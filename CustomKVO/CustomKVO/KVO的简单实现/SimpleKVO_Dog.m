//
//  SimpleKVO_Dog.m
//  CustomKVO
//
// ********************************************
// *          _____             _____         *
// *          \   /             \   /         *
// *          /  /              /  /          *
// *         /  /              /  /           *
// *        /  /__            /  /__          *
// *       /_____/           /_____/          *
// *                                          *
// ********************************************
//
//  Created by 李磊 on 2017/4/19.
//  Copyright © 2017年 李磊www. All rights reserved.
//

#import "SimpleKVO_Dog.h"
#import <objc/runtime.h>
#import "NSObject+SimpleKVO.h"

extern NSString *const ObserverKey;
@implementation SimpleKVO_Dog
- (void)setName:(NSString *)name{
    // 保存旧值
    NSString *oldName = self.name;
    // 调用父类方法
    [super setName:name];
    // 获取观察者
    id obsetver = objc_getAssociatedObject(self, ObserverKey);
    NSDictionary<NSKeyValueChangeKey,id> *changeDict = oldName ? @{NSKeyValueChangeNewKey : name, NSKeyValueChangeOldKey : oldName} : @{NSKeyValueChangeNewKey : name};
    // 调用回调方法，传递旧值和新值
    [obsetver ll_observeValueForKeyPath:@"name" ofObject:self change:changeDict context:nil];
}

@end
