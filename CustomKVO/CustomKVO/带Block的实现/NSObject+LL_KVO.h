//
//  NSObject+LL_KVO.h
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
//  Created by 李磊 on 2017/4/24.
//  Copyright © 2017年 李磊www. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^LLKVOBlock)(id observer, NSString *key, id oldValue, id newValue);


@interface NSObject (LL_KVO)

/**
 添加观察者
 */
- (void)ll_addObserver:(id)observer key:(NSString *)key callback:(LLKVOBlock)callback;


/**
 移除观察者
 */
- (void)ll_removeObserver:(id)observer key:(NSString *)key;

@end
