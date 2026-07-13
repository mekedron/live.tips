/// The real Cloud KMS KeyWrapper. One symmetric key wraps every DEK; the
/// functions' service account holds cryptoKeyEncrypterDecrypter on that key
/// and NOTHING here ever holds key material beyond the call (see
/// stripe-crypto.ts for the envelope scheme and README.md for the exact
/// `gcloud` setup + IAM).
///
/// The key resource defaults to
///   projects/<project>/locations/europe-west1/keyRings/livetips/cryptoKeys/stripe-secrets
/// and can be overridden with the KMS_KEY_RESOURCE string param (emulators,
/// staging). Fail closed: no resolvable project, no wrapper — the callers
/// refuse the request rather than store anything unencrypted.

import { KeyManagementServiceClient } from "@google-cloud/kms";
import { defineString } from "firebase-functions/params";
import type { KeyWrapper } from "./stripe-crypto";

export const KMS_KEY_RESOURCE = defineString("KMS_KEY_RESOURCE", { default: "" });

let client: KeyManagementServiceClient | null = null;

function kmsClient(): KeyManagementServiceClient {
  if (client === null) client = new KeyManagementServiceClient();
  return client;
}

/** The key resource the runtime should use, or null when unresolvable. */
export function resolveKmsKeyName(): string | null {
  const override = KMS_KEY_RESOURCE.value();
  if (override) return override;
  const project = process.env["GCLOUD_PROJECT"] ?? process.env["GOOGLE_CLOUD_PROJECT"] ?? "";
  if (!project) return null;
  return `projects/${project}/locations/europe-west1/keyRings/livetips/cryptoKeys/stripe-secrets`;
}

export function kmsKeyWrapper(): KeyWrapper {
  const kmsKeyName = resolveKmsKeyName();
  if (!kmsKeyName) throw new Error("KMS key resource is not configured");
  return {
    kmsKeyName,
    async wrap(dek: Buffer): Promise<Buffer> {
      const [res] = await kmsClient().encrypt({ name: kmsKeyName, plaintext: dek });
      if (!res.ciphertext) throw new Error("KMS returned no ciphertext");
      return Buffer.from(res.ciphertext as Uint8Array);
    },
    async unwrap(wrapped: Buffer): Promise<Buffer> {
      const [res] = await kmsClient().decrypt({ name: kmsKeyName, ciphertext: wrapped });
      if (!res.plaintext) throw new Error("KMS returned no plaintext");
      return Buffer.from(res.plaintext as Uint8Array);
    },
  };
}
