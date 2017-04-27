//
//  NSObject+SimpleKVO.h
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

#import <Foundation/Foundation.h>

@interface NSObject (SimpleKVO)
// 添加观察者
- (void)ll_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context;
// 属性改变的回调方法
- (void)ll_observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context;
@end
