//
//  do_IndexListView_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_IndexListView_IView <NSObject>

@required
//属性方法
- (void)change_selectedColor:(NSString *)newValue;
- (void)change_templates:(NSString *)newValue;

//同步或异步方法
- (void)bindItems:(NSArray *)parms;
- (void)refreshItems:(NSArray *)parms;


@end