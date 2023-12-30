require 'digest'

class JsonHelper
  # fetched 12/20/2023 from https://w3c-ccg.github.io/security-vocab/contexts/security-v1.jsonld
  #
  NIFTY_JSON_DEPENDENCY = {"@context"=>
  {"id"=>"@id",
   "type"=>"@type",
   "dc"=>"http://purl.org/dc/terms/",
   "sec"=>"https://w3id.org/security#",
   "xsd"=>"http://www.w3.org/2001/XMLSchema#",
   "Ed25519Signature2018"=>"sec:Ed25519Signature2018",
   "EncryptedMessage"=>"sec:EncryptedMessage",
   "GraphSignature2012"=>"sec:GraphSignature2012",
   "LinkedDataSignature2015"=>"sec:LinkedDataSignature2015",
   "LinkedDataSignature2016"=>"sec:LinkedDataSignature2016",
   "CryptographicKey"=>"sec:Key",
   "authenticationTag"=>"sec:authenticationTag",
   "canonicalizationAlgorithm"=>"sec:canonicalizationAlgorithm",
   "cipherAlgorithm"=>"sec:cipherAlgorithm",
   "cipherData"=>"sec:cipherData",
   "cipherKey"=>"sec:cipherKey",
   "created"=>{"@id"=>"dc:created", "@type"=>"xsd:dateTime"},
   "creator"=>{"@id"=>"dc:creator", "@type"=>"@id"},
   "digestAlgorithm"=>"sec:digestAlgorithm",
   "digestValue"=>"sec:digestValue",
   "domain"=>"sec:domain",
   "encryptionKey"=>"sec:encryptionKey",
   "expiration"=>{"@id"=>"sec:expiration", "@type"=>"xsd:dateTime"},
   "expires"=>{"@id"=>"sec:expiration", "@type"=>"xsd:dateTime"},
   "initializationVector"=>"sec:initializationVector",
   "iterationCount"=>"sec:iterationCount",
   "nonce"=>"sec:nonce",
   "normalizationAlgorithm"=>"sec:normalizationAlgorithm",
   "owner"=>{"@id"=>"sec:owner", "@type"=>"@id"},
   "password"=>"sec:password",
   "privateKey"=>{"@id"=>"sec:privateKey", "@type"=>"@id"},
   "privateKeyPem"=>"sec:privateKeyPem",
   "publicKey"=>{"@id"=>"sec:publicKey", "@type"=>"@id"},
   "publicKeyBase58"=>"sec:publicKeyBase58",
   "publicKeyPem"=>"sec:publicKeyPem",
   "publicKeyWif"=>"sec:publicKeyWif",
   "publicKeyService"=>{"@id"=>"sec:publicKeyService", "@type"=>"@id"},
   "revoked"=>{"@id"=>"sec:revoked", "@type"=>"xsd:dateTime"},
   "salt"=>"sec:salt",
   "signature"=>"sec:signature",
   "signatureAlgorithm"=>"sec:signingAlgorithm",
   "signatureValue"=>"sec:signatureValue"}}

  def self.canonicalize(json)
    rdf = JSON::LD::API.toRdf(json, documentLoader: method(:load_jsonld_context))
    graph = RDF::Graph.new << rdf
    graph.dump(:normalize)
  end

  private

  def self.load_jsonld_context(url, _options = {}, &_block)
    doc = JSON::LD::API::RemoteDocument.new(NIFTY_JSON_DEPENDENCY, documentUrl: url)
    block_given? ? yield(doc) : doc
  end
end
