//
//  HMAC.swift
//  AWSSDKSwift
//
//  Created by Yuki Takei on 2017/03/13.
//
//

import CommonCrypto

func hmac(string: String, key: [UInt8]) -> [UInt8] {
    var context = CCHmacContext()
    CCHmacInit(&context, CCHmacAlgorithm(kCCHmacAlgSHA256), key, key.count)
    //HMAC_Init(&context, key, key.count, SSL_EVP_sha256(), nil)

    let bytes = Array(string.utf8)
    CCHmacUpdate(&context, bytes, bytes.count)
//    HMAC_Update(&context, bytes, bytes.count)
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    //var length: UInt32 = 0
    CCHmacFinal(&context, &digest)
//    HMAC_Final(&context, &digest, &length)

//    HMAC_CTX_cleanup(&context)

    return digest//Array(digest[0..<Int(length)])
}
