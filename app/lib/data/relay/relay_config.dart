/// Where the live.tips relay worker lives. One base for the REST API and a
/// helper for the per-jar WebSocket feed.
const String kRelayApiBase = 'https://api.live.tips';

Uri relayWsUri(String jarId) =>
    Uri.parse('wss://api.live.tips/v1/jars/$jarId/ws');

Uri relayApi(String path) => Uri.parse('$kRelayApiBase$path');
