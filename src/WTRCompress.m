//
//  WTRCompress.m
//  zipAndrar
//
//  Created by wfz on 2019/10/10.
//  Copyright © 2019 wfz. All rights reserved.
//

#import "WTRCompress.h"
#import "zip.h"
#import "unzip.h"

#import <UnrarKit/UnrarKit.h>
#import <LzmaSDK_ObjC/LzmaSDKObjCReader.h>
#import <LzmaSDK_ObjC/LzmaSDKObjCWriter.h>

@interface WTRCompress ()<LzmaSDKObjCReaderDelegate,LzmaSDKObjCWriterDelegate>

@property(nonatomic,copy) void (^pcb)(float);
@property(nonatomic,copy) void (^completion)(int rets);

@end

@implementation WTRCompress
{
    NSString *_password;

    //zip压缩
    zipFile _zipf;

    //zip解压缩
    unzFile _unzipf;

    //7z
    LzmaSDKObjCReader *_lzreader;
    LzmaSDKObjCWriter *_lzwriter;
}

#pragma mark zip压缩
-(BOOL)zipOpenFile:(NSString *)fpath password:(NSString*)password
{
    _zipf=zipOpen(fpath.UTF8String,0);
    if(!_zipf){
        return NO;
    }
    _password=password;
    return YES;
}
-(void)setfileinfo:(zip_fileinfo *)zipInfo fPath:(NSString *)fPath
{
    NSDate* fileDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:fPath error:nil] objectForKey:NSFileModificationDate];
    if(fileDate){
        // some application does use dosDate, but tmz_date instead
    //    zipInfo.dosDate = [fileDate timeIntervalSinceDate:[self Date1980] ];
        NSCalendar* currCalendar = [NSCalendar currentCalendar];
        NSCalendarUnit flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
            NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ;
        NSDateComponents* dc = [currCalendar components:flags fromDate:fileDate];
        zipInfo->tmz_date.tm_sec = (uInt)[dc second];
        zipInfo->tmz_date.tm_min = (uInt)[dc minute];
        zipInfo->tmz_date.tm_hour = (uInt)[dc hour];
        zipInfo->tmz_date.tm_mday = (uInt)[dc day];
        zipInfo->tmz_date.tm_mon = (uInt)[dc month] - 1;
        zipInfo->tmz_date.tm_year = (uInt)[dc year];
    }
}
-(BOOL)zipAddFile:(NSString *)fpath fileNameInZip:(NSString *)fileNameInZip
{
    if(!_zipf){
        return NO;
    }

    zip_fileinfo zipInfo = {0};
    [self setfileinfo:&zipInfo fPath:fpath];

    int ret ;
    NSData* data = nil;
    if (_password&&_password.length>0) {
        data = [NSData dataWithContentsOfFile:fpath];
        uLong crcValue = crc32( 0L,NULL, 0L );
        crcValue = crc32(crcValue, (const Bytef*)[data bytes],(uInt)[data length]);
        ret = zipOpenNewFileInZip3(_zipf,
                                  [fileNameInZip UTF8String],
                                  &zipInfo,
                                  NULL,0,
                                  NULL,0,
                                  NULL,//comment
                                  Z_DEFLATED,
                                  Z_DEFAULT_COMPRESSION,
                                  0,
                                  15,
                                  8,
                                  Z_DEFAULT_STRATEGY,
                                  [_password cStringUsingEncoding:NSASCIIStringEncoding],
                                  crcValue);
    }else{
        ret = zipOpenNewFileInZip(_zipf,
                                  [fileNameInZip UTF8String],
                                  &zipInfo,
                                  NULL,0,NULL,0,NULL,//comment
                                  Z_DEFLATED,
                                  Z_DEFAULT_COMPRESSION);
    }

    if(ret!=Z_OK){
        return NO;
    }
    if(data==nil){
        data = [NSData dataWithContentsOfFile:fpath];
    }
    unsigned dataLen = (unsigned)[data length];
    ret = zipWriteInFileInZip(_zipf,[data bytes],dataLen);
    if(ret!=Z_OK){
        return NO;
    }
    ret = zipCloseFileInZip(_zipf);
    if(ret!=Z_OK){
        return NO;
    }
    return YES;
}
-(BOOL)zipAddFolderAtPath:(NSString *)fpath folderName:(NSString *)folderName
{
    zip_fileinfo zipInfo = {0};
    [self setfileinfo:&zipInfo fPath:fpath];

    int ret ;
    if (_password&&_password.length>0) {
        uLong crcValue = crc32( 0L,NULL, 0L );
        ret = zipOpenNewFileInZip3(_zipf,
                                  [[folderName stringByAppendingString:@"/"] UTF8String],
                                  &zipInfo,
                                  NULL,0,
                                  NULL,0,
                                  NULL,//comment
                                  Z_DEFLATED,
                                  Z_NO_COMPRESSION,
                                  0,
                                  15,
                                  8,
                                  Z_DEFAULT_STRATEGY,
                                  [_password cStringUsingEncoding:NSASCIIStringEncoding],
                                  crcValue);
    }else{
        ret = zipOpenNewFileInZip(_zipf,
                                  [[folderName stringByAppendingString:@"/"] UTF8String],
                                  &zipInfo,
                                  NULL,0,NULL,0,NULL,//comment
                                  Z_DEFLATED,
                                  Z_NO_COMPRESSION);
    }

    if(ret!=Z_OK){
        return NO;
    }
    const void *buffer = NULL;
    ret = zipWriteInFileInZip(_zipf,buffer,0);
    if(ret!=Z_OK){
        return NO;
    }
    ret = zipCloseFileInZip(_zipf);
    if(ret!=Z_OK){
        return NO;
    }
    return YES;
}
-(BOOL)zipCloseFile
{
    _password = nil;
    if(_zipf==NULL )
        return NO;
    BOOL ret = zipClose(_zipf,NULL)==Z_OK?YES:NO;
    _zipf = NULL;
    return ret;
}

#pragma mark zip解压缩
-(BOOL)unzipOpenFile:(NSString*)fpath password:(NSString*)password
{
    _unzipf = unzOpen([fpath UTF8String]);
    if(_unzipf){
        unz_global_info globalInfo = {0};
        if(unzGetGlobalInfo(_unzipf,&globalInfo)==UNZ_OK )
        {
            NSLog(@"%lu entries in the zip file",globalInfo.number_entry);
        }
        _password=password;
    }
    return _unzipf!=NULL;
}
-(int)unzipFileTo:(NSString*)fpath overWrite:(BOOL)overwrite
{
    int ret = unzGoToFirstFile(_unzipf);

    NSFileManager* fman = [NSFileManager defaultManager];
    if(ret!=UNZ_OK) {
        return NO;
    }

    unsigned char buffer[4096] = {0};
    int success = 1;
    do{
        if (_password&&_password.length>0) {
            ret = unzOpenCurrentFilePassword(_unzipf,[_password cStringUsingEncoding:NSASCIIStringEncoding]);
        }else{
            ret = unzOpenCurrentFile(_unzipf);
        }

        if(ret!=UNZ_OK){
            success = 0;
            break;
        }
        // reading data and write to file
        int read ;
        unz_file_info   fileInfo = {0};
        ret = unzGetCurrentFileInfo(_unzipf, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
        if(ret!=UNZ_OK ){
            success = 0;
            unzCloseCurrentFile(_unzipf);
            break;
        }
        char *filename = (char*)malloc(fileInfo.size_filename+1);
        unzGetCurrentFileInfo(_unzipf, &fileInfo, filename, fileInfo.size_filename + 1, NULL, 0, NULL, 0);
        filename[fileInfo.size_filename] = '\0';

        NSData *fnameda=[NSData dataWithBytes:filename length:fileInfo.size_filename];
        // check if it contains directory
        NSString * strPath = [self deCodeStrWithData:fnameda];//[NSString stringWithUTF8String:filename];
        BOOL isDirectory = NO;
        if( filename[fileInfo.size_filename-1]=='/' || filename[fileInfo.size_filename-1]=='\\')
            isDirectory = YES;
        free(filename);
        if( [strPath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/\\"]].location!=NSNotFound )
        {// contains a path
            strPath = [strPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
        }
        NSString* fullPath = [fpath stringByAppendingPathComponent:strPath];

        if(isDirectory){
            [fman createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
        }else{
            [fman createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];

            if([fman fileExistsAtPath:fullPath]&&!overwrite){
                unzCloseCurrentFile(_unzipf);
                ret = unzGoToNextFile(_unzipf);
                continue;
            }

            FILE* fp = fopen([fullPath UTF8String], "wb");
            while(fp){
                read=unzReadCurrentFile(_unzipf, buffer, 4096);
                if(read>0){
                    fwrite(buffer, read, 1, fp );
                }else if( read<0 ){
                    NSLog(@"Failed to reading zip file");
                    success=read;
                    break;
                }else{
                    break;
                }
            }
            if(fp) {
                fclose(fp);

                //时间
                NSDateComponents *dc = [[NSDateComponents alloc] init];
                dc.second = fileInfo.tmu_date.tm_sec;
                dc.minute = fileInfo.tmu_date.tm_min;
                dc.hour = fileInfo.tmu_date.tm_hour;
                dc.day = fileInfo.tmu_date.tm_mday;
                dc.month = fileInfo.tmu_date.tm_mon+1;
                dc.year = fileInfo.tmu_date.tm_year;
                NSDate*orgDate = [[NSCalendar currentCalendar] dateFromComponents:dc];
                if (orgDate) {
                    [[NSFileManager defaultManager] setAttributes:@{NSFileModificationDate:orgDate} ofItemAtPath:fullPath error:nil];
                }
            }
        }

        unzCloseCurrentFile(_unzipf);
        ret = unzGoToNextFile(_unzipf);
    }while( ret==UNZ_OK && UNZ_OK!=UNZ_END_OF_LIST_OF_FILE );
    return success;
}
-(BOOL)unzipCloseFile
{
    _password = nil;
    if(_unzipf){
        return unzClose(_unzipf)==UNZ_OK;
    }
    return NO;
}

#pragma mark 字符串解码
-(NSString *)deCodeStrWithData:(NSData *)da
{
    NSString *retstr=[[NSString alloc] initWithData:da encoding:NSUTF8StringEncoding];
    if (!retstr) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        retstr = [[NSString alloc] initWithData:da encoding:enc];
    }
    if (!retstr) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_2312_80);
        retstr = [[NSString alloc] initWithData:da encoding:enc];
    }
    if (!retstr) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGBK_95);
        retstr = [[NSString alloc] initWithData:da encoding:enc];
    }
    if (!retstr) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSChineseSimplif);
        retstr = [[NSString alloc] initWithData:da encoding:enc];
    }
    if (!retstr) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingMacChineseSimp);
        retstr = [[NSString alloc] initWithData:da encoding:enc];
    }
    if (!retstr) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingHZ_GB_2312);
        retstr = [[NSString alloc] initWithData:da encoding:enc];
    }
    if (!retstr) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_CN);
        retstr = [[NSString alloc] initWithData:da encoding:enc];
    }
    if (!retstr) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_CN_EXT);
        retstr = [[NSString alloc] initWithData:da encoding:enc];
    }
    if (!retstr) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSChineseTrad);
        retstr = [[NSString alloc] initWithData:da encoding:enc];
    }
    if (!retstr) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_CN);
        retstr = [[NSString alloc] initWithData:da encoding:enc];
    }
    if (!retstr) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5);
        retstr = [[NSString alloc] initWithData:da encoding:enc];
    }
    if (!retstr) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUnicode);
        retstr = [[NSString alloc] initWithData:da encoding:enc];
    }
    if (!retstr) {
        retstr = [[NSString alloc] initWithData:da encoding:NSUTF16StringEncoding];
    }
    return retstr;
}

#pragma mark 封装方法
+ (BOOL)createZipFileAtPath:(NSString *)zipPath withFilesAtPaths:(NSArray<NSString *> *)paths withPassword:(nullable NSString *)password
{
    if (!paths||paths.count==0) {
        return NO;
    }
    WTRCompress *compre=[WTRCompress new];
    BOOL ret=[compre zipOpenFile:zipPath password:password];
    if (!ret) {
        return NO;
    }
    for (int i=0; i<paths.count; i++) {
        NSString *cpath=paths[i];
        BOOL isdir;
        BOOL isfz=[[NSFileManager defaultManager] fileExistsAtPath:cpath isDirectory:&isdir];
        if (isfz) {
            if (isdir) {
                NSString *wjjname=[cpath lastPathComponent];
                NSArray *warr=[[NSFileManager defaultManager] subpathsAtPath:cpath];
                for (NSString *subp in warr) {
                    if ([subp hasPrefix:@"."]||[subp rangeOfString:@"/."].length>0) {
                        continue;
                    }
                    NSString *subpathf=[cpath stringByAppendingPathComponent:subp];
                    BOOL issubdir;
                    [[NSFileManager defaultManager] fileExistsAtPath:subpathf isDirectory:&issubdir];
                    if (!issubdir) {
                        BOOL addret=[compre zipAddFile:subpathf fileNameInZip:[wjjname stringByAppendingPathComponent:subp]];
                        if(!addret){
                            NSLog(@"添加文件失败：%@",subpathf);
                        }
                    }else{
                        if (![[NSFileManager defaultManager] enumeratorAtPath:subpathf].nextObject) {
                            // empty directory
                            BOOL addret=[compre zipAddFolderAtPath:subpathf folderName:[wjjname stringByAppendingPathComponent:subp]];
                            if(!addret){
                                NSLog(@"添加空文件夹失败：%@",subpathf);
                            }
                        }
                    }
                }
            }else{
                BOOL addret=[compre zipAddFile:cpath fileNameInZip:[cpath lastPathComponent]];
                if(!addret){
                    NSLog(@"添加文件失败：%@",cpath);
                }
            }
        }
    }
    [compre zipCloseFile];
    return YES;
}
+ (int)unzip:(NSString *)zipPath toPath:(NSString *)toPath password:(nullable NSString *)password
{
    WTRCompress *compre=[WTRCompress new];
    int ret=[compre unzipOpenFile:zipPath password:password];
    if (!ret) {
        return NO;
    }
    ret=[compre unzipFileTo:toPath overWrite:YES];

    [compre unzipCloseFile];
    return ret;
}

#pragma mark rar解压
+ (int)unRar:(NSString *)rarPath toPath:(NSString *)toPath password:(nullable NSString *)password
{
    NSError *archiveError = nil;
    URKArchive *archive = [[URKArchive alloc] initWithPath:rarPath password:password error:&archiveError];
    if (archiveError) {
        NSLog(@"%@",archiveError);
        return 0;
    }
    NSError *error = nil;
    [archive extractFilesTo:toPath overwrite:YES error:&error];
    if (error) {
        NSLog(@"%@",error);
        if (error.code==ERAR_MISSING_PASSWORD) {
            NSLog(@"密码错误");
            return -3;
        }
        return 0;
    }
    return 1;
}

-(void)un7z:(NSString *)fPath password:(nullable NSString *)password toPath:(NSString *)toPath
{
    _lzreader = [[LzmaSDKObjCReader alloc] initWithFileURL:[NSURL fileURLWithPath:fPath] andType:LzmaSDKObjCFileType7z];

    _lzreader.delegate=self;
    _lzreader.passwordGetter = ^NSString*(void){
        return password;
    };

    NSError * error = nil;
    if (![_lzreader open:&error]) {
        NSLog(@"Open error: %@", error);
    }
    NSLog(@"Open error: %@", _lzreader.lastError);

    NSMutableArray * items = [NSMutableArray array]; // Array with selected items.
    // Iterate all archive items, track what items do you need & hold them in array.
    [_lzreader iterateWithHandler:^BOOL(LzmaSDKObjCItem * item, NSError * error){
        NSLog(@"\n%@", item);
        if (item) [items addObject:item]; // If needed, store to array.
        return YES; // YES - continue iterate, NO - stop iteration
    }];
    NSLog(@"Iteration error: %@", _lzreader.lastError);

    [_lzreader extract:items
              toPath:toPath
        withFullPaths:YES];

    NSLog(@"Extract error: %@", _lzreader.lastError);

    if (self.completion) {
        if (_lzreader.lastError) {
            if (_lzreader.lastError.code==-2147467259) {
                NSLog(@"密码错误");
                self.completion(-3);
            }else{
                self.completion(0);
            }
        }else{
            self.completion(1);
        }
    }

    // Test selected items from prev. step.
//    [_reader test:items];
//    NSLog(@"test error: %@", _reader.lastError);

}
- (void) onLzmaSDKObjCReader:(nonnull LzmaSDKObjCReader *) reader extractProgress:(float) progress
{
    //解压7z进度
    NSLog(@"extractProgress:%.2f",progress);
    if (self.pcb) {
        self.pcb(progress);
    }
}

- (void)create7zFileAtPath:(NSString *)fPath withFilesAtPaths:(NSArray<NSString *> *)paths withPassword:(nullable NSString *)password
{
    // Create writer
    _lzwriter = [[LzmaSDKObjCWriter alloc] initWithFileURL:[NSURL fileURLWithPath:fPath]];

    for (int i=0; i<paths.count; i++) {
        NSString *cpath=paths[i];
        BOOL addret=[_lzwriter addPath:cpath forPath:[cpath lastPathComponent]];
        if(!addret){
            NSLog(@"添加文件失败：%@",cpath);
        }
    }

    // Add file data's or paths
//    [writer addData:[NSData ...] forPath:@"MyArchiveFileName.txt"]; // Add file data
//    [writer addPath:@"/Path/somefile.txt" forPath:@"archiveDir/somefile.txt"]; // Add file at path
//    [writer addPath:@"/Path/SomeDirectory" forPath:@"SomeDirectory"]; // Recursively add directory with all contents

    // Setup writer
    _lzwriter.delegate = self; // Track progress
    _lzwriter.passwordGetter = ^NSString*(void) { // Password getter
        return password;
    };

    // Optional settings
    _lzwriter.method = LzmaSDKObjCMethodLZMA2; // or LzmaSDKObjCMethodLZMA
    _lzwriter.solid = YES;
    _lzwriter.compressionLevel = 9;
    _lzwriter.encodeContent = YES;
    _lzwriter.encodeHeader = YES;
    _lzwriter.compressHeader = YES;
    _lzwriter.compressHeaderFull = YES;
    _lzwriter.writeModificationTime = NO;
    _lzwriter.writeCreationTime = NO;
    _lzwriter.writeAccessTime = NO;

    // Open archive file
    NSError * error = nil;
    [_lzwriter open:&error];

    [_lzwriter write];

    if (self.completion) {
        if (error) {
            NSLog(@"%@",error);
            self.completion(0);
        }else{
            self.completion(1);
        }
    }
}
- (void) onLzmaSDKObjCWriter:(nonnull LzmaSDKObjCWriter *) writer writeProgress:(float) progress
{
    //压缩7z进度
    NSLog(@"writeProgress:%.2f",progress);
    if (self.pcb) {
        self.pcb(progress);
    }
}

#pragma mark 7z解压  .7z
+ (void)un7z:(NSString *)fPath toPath:(NSString *)toPath password:(nullable NSString *)password progress:(void (^ __nullable)(float progress))pcb completion:(void (^ __nullable)(int rets))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        WTRCompress *compres=[WTRCompress new];
        compres.pcb=pcb;
        compres.completion = completion;
        [compres un7z:fPath password:password toPath:toPath];
    });
}
#pragma mark 7z压缩  .7z
+ (void)create7zFileAtPath:(NSString *)fPath withFilesAtPaths:(NSArray<NSString *> *)paths withPassword:(nullable NSString *)password progress:(void (^)(float progress))pcb  completion:(void (^)(int rets))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        WTRCompress *compres=[WTRCompress new];
        compres.pcb=pcb;
        compres.completion = completion;
        [compres create7zFileAtPath:fPath withFilesAtPaths:paths withPassword:password];
    });
}

@end
