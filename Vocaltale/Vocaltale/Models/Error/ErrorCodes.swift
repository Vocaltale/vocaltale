//
//  ErrorCodes.swift
//  Vocaltale
//
//  Created by Kei Sau CHING on 2022/9/27.
//

import Foundation

public let kSystemError: Int = 0xf000_0000
public let kSystemError_UserDefaults: Int = kSystemError | 0x0100_0000

public let kSystemError_UserDefaults_InitializationFailed: Int = kSystemError_UserDefaults | 0xffff

public let kSystemError_Library: Int = kSystemError | 0x0200_0000
public let kSystemError_Library_NotOpened: Int = kSystemError_Library | 0x0001
