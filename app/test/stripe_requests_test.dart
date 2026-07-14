import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:live_tips/data/stripe/stripe_client.dart';
import 'package:live_tips/data/stripe/stripe_requests.dart';

// Assembled, never literal — a key-shaped string in the source would trip
// GitHub push protection, and rightly so.
final _apiKey = ['rk', 'test', 'param_encoding_fake'].join('_');

/// Captures every POST body by path and answers with scripted objects, in
/// the order Stripe's create-song-link dance asks for them.
class _Recorder {
  final List<http.Request> posts = [];

  MockClient client() => MockClient((request) async {
        if (request.method == 'POST') posts.add(request);
        final path = request.url.path;
        Map<String, Object> body;
        if (path == '/v1/products') {
          body = {'id': 'prod_song1'};
        } else if (path == '/v1/prices') {
          body = {'id': 'price_song1'};
        } else if (path == '/v1/payment_links') {
          body = {
            'id': 'plink_song1',
            'url': 'https://buy.stripe.com/test_song1',
            'livemode': false,
          };
        } else {
          body = {'id': path.split('/').last};
        }
        return http.Response(jsonEncode(body), 200,
            headers: {'content-type': 'application/json'});
      });

  http.Request postTo(String path) =>
      posts.firstWhere((r) => r.url.path == path);
}

void main() {
  test(
      'createSongLink mints product → fixed price → payment link, parameter '
      'for parameter the server proxy op (votes 1–50, pay, the jar\'s fan '
      'fields, song_id metadata everywhere)', () async {
    final recorder = _Recorder();
    final requests =
        StripeRequests(StripeClient(_apiKey, httpClient: recorder.client()));

    final record = await requests.createSongLink(
      songId: 'sng_abc123',
      title: 'Wonderwall',
      priceMinor: 750,
      currency: 'eur',
    );

    final product = recorder.postTo('/v1/products');
    expect(product.headers['Authorization'], 'Bearer $_apiKey');
    expect(product.bodyFields, {
      'name': 'Request — Wonderwall',
      'metadata[managed_by]': 'live.tips',
      'metadata[song_id]': 'sng_abc123',
    });

    final price = recorder.postTo('/v1/prices');
    expect(price.bodyFields, {
      'product': 'prod_song1',
      'currency': 'eur',
      'unit_amount': '750',
      'metadata[managed_by]': 'live.tips',
    });

    final link = recorder.postTo('/v1/payment_links');
    expect(link.bodyFields, {
      'line_items[0][price]': 'price_song1',
      'line_items[0][quantity]': '1',
      'line_items[0][adjustable_quantity][enabled]': 'true',
      'line_items[0][adjustable_quantity][minimum]': '1',
      'line_items[0][adjustable_quantity][maximum]': '50',
      'submit_type': 'pay',
      'custom_fields[0][key]': 'nickname',
      'custom_fields[0][label][type]': 'custom',
      'custom_fields[0][label][custom]': 'Your name or nickname',
      'custom_fields[0][type]': 'text',
      'custom_fields[0][optional]': 'true',
      'custom_fields[1][key]': 'message',
      'custom_fields[1][label][type]': 'custom',
      'custom_fields[1][label][custom]': 'Leave a message',
      'custom_fields[1][type]': 'text',
      'custom_fields[1][optional]': 'true',
      'metadata[managed_by]': 'live.tips',
      'metadata[song_id]': 'sng_abc123',
    });

    // The record stores what the link was minted FOR — price and title are
    // how staleness against the live song is detected later.
    expect(record.productId, 'prod_song1');
    expect(record.priceId, 'price_song1');
    expect(record.paymentLinkId, 'plink_song1');
    expect(record.url, 'https://buy.stripe.com/test_song1');
    expect(record.priceMinor, 750);
    expect(record.title, 'Wonderwall');
  });

  test('deactivateSongLink turns the link off, nothing else', () async {
    final recorder = _Recorder();
    final requests =
        StripeRequests(StripeClient(_apiKey, httpClient: recorder.client()));

    await requests.deactivateSongLink('plink_song1');

    expect(recorder.posts, hasLength(1));
    expect(recorder.posts.single.url.path, '/v1/payment_links/plink_song1');
    expect(recorder.posts.single.bodyFields, {'active': 'false'});
  });

  test('renameSongProduct renames in place, keeping the Request — prefix',
      () async {
    final recorder = _Recorder();
    final requests =
        StripeRequests(StripeClient(_apiKey, httpClient: recorder.client()));

    await requests.renameSongProduct(
        productId: 'prod_song1', title: 'Champagne Supernova');

    expect(recorder.posts, hasLength(1));
    expect(recorder.posts.single.url.path, '/v1/products/prod_song1');
    expect(recorder.posts.single.bodyFields,
        {'name': 'Request — Champagne Supernova'});
  });
}
