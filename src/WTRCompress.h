//
//  WTRCompress.h
//  zipAndrar
//
//  Created by wfz on 2019/10/10.
//  Copyright © 2019 wfz. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WTRCompress : NSObject

/*
 zip解压 .zip
 同步线程
 返回-3是需要密码  返回1成功
 */
+ (int)unzip:(NSString *)zipPath toPath:(NSString *)toPath password:(nullable NSString *)password;

/*
 rar解压  .rar
 同步线程
 返回-3是需要密码  返回1成功
*/
+ (int)unRar:(NSString *)rarPath toPath:(NSString *)toPath password:(nullable NSString *)password;

/*
 7z解压  .7z
 异步线程
 */
+ (void)un7z:(NSString *)fPath toPath:(NSString *)toPath password:(nullable NSString *)password progress:(void (^ __nullable)(float progress))pcb completion:(void (^ __nullable)(int rets))completion;


/*
 zip压缩 .zip
 同步线程
 paths 数组内可以是文件夹路径也可以是文件路径
 */
+ (BOOL)createZipFileAtPath:(NSString *)zipPath withFilesAtPaths:(NSArray<NSString *> *)paths withPassword:(nullable NSString *)password;

/*
 7z压缩  .7z
 异步线程
 paths 数组内可以是文件夹路径也可以是文件路径
 */
+ (void)create7zFileAtPath:(NSString *)fPath withFilesAtPaths:(NSArray<NSString *> *)paths withPassword:(nullable NSString *)password progress:(void (^ __nullable)(float progress))pcb  completion:(void (^ __nullable)(int rets))completion;

@end

NS_ASSUME_NONNULL_END
