//
//  ViewController.m
//  WTRCompress
//
//  Created by wfz on 2019/10/10.
//  Copyright © 2019 wfz. All rights reserved.
//

#import "ViewController.h"
#import "WTRCompress.h"
//#import "SSZipArchive.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    NSLog(@"%@",NSHomeDirectory());

//    NSString *fpath=[NSHomeDirectory() stringByAppendingPathComponent:@"Library/example2.zip"];

//    [SSZipArchive createZipFileAtPath:[fpath stringByAppendingPathExtension:@"zip"] withContentsOfDirectory:fpath];

//    NSString *fpath2=[NSHomeDirectory() stringByAppendingPathComponent:@"Library/example2/__MACOSX"];

//    [WTRCompress unzip:fpath toPath:[fpath stringByDeletingPathExtension] password:@""];

//    [WTRCompress createZipFileAtPath:[fpath stringByAppendingPathExtension:@"zip"] withFilesAtPaths:@[fpath] withPassword:@""];

    //SARUnArchiveANY_7z
//    [WTRCompress un7z:fpath password:@"SARUnArchiveANY_7z" toPath:[fpath stringByDeletingPathExtension] progress:^(float pro) {
//    }];

    //SARUnArchiveANY_RAR
//    [WTRCompress unRar:fpath password:@"SARUnArchiveANY_RAR" toPath:[fpath stringByDeletingPathExtension]];

//    [WTRCompress unzip:fpath toPath:[fpath stringByDeletingPathExtension] password:@""];

}


@end
