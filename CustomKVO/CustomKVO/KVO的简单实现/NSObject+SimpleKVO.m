//
//  NSObject+SimpleKVO.m
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

#import "NSObject+SimpleKVO.h"
#import "SimpleKVO_Dog.h"
NSString *const ObserverKey = @"ObserverKey";
#import <objc/runtime.h>

@implementation NSObject (SimpleKVO)
- (void)ll_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context{
    // 保存观察者
    objc_setAssociatedObject(self, (__bridge const void *)(ObserverKey), observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    // 修改isa指针指向的类(指向了Dog子类)，这里将指向的类写死了
    object_setClass(self, [SimpleKVO_Dog class]);
}

// 这里做是为了容错处理
- (void)ll_observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context{}

@end
