//
//  ViewController.m
//  CustomKVO
//
//  Created by 李磊 on 2017/4/19.
//  Copyright © 2017年 李磊www. All rights reserved.
//

#import "ViewController.h"
#import "Dog.h"
#import "SimpleKVO_Dog.h"
#import "NSObject+SimpleKVO.h"
#import "NSObject+LL_KVO.h"
#import <objc/runtime.h>

@interface ViewController ()

@property(nonatomic,strong) Dog *dog;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    请选择要测试的选项
   // 系统KVO测试
//    [self systemKVOTest];
    
    // 简单KVO测试
//    [self simpleKVOTest];
    
    // block KVO测试
//    [self blockKVOTest];
}


#pragma mark - 系统KVO测试
- (void)systemKVOTest{
    self.dog =  [Dog new];
    NSLog(@"%@",object_getClass(self.dog));
    [self.dog addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew |
     NSKeyValueObservingOptionOld context:nil];
    NSLog(@"%@",object_getClass(self.dog));
    [self.dog removeObserver:self forKeyPath:@"age"];
    NSLog(@"%@",object_getClass(self.dog));
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    NSLog(@"%@",[change[NSKeyValueChangeNewKey] class]);

}

#pragma mark - 简单KVO测试

- (void)simpleKVOTest{
    Dog *dog =  [Dog new];
    [dog ll_addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew |
     NSKeyValueObservingOptionOld context:nil];
    dog.name = @"aaa";
    dog.name = @"bbb";
}
- (void)ll_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSLog(@"%@",change);
}


- (void)blockKVOTest{
    
    Dog *dog =  [Dog new];
    
    NSLog(@"%@",object_getClass(dog));//Dog
    
    [dog ll_addObserver:self key:@"name" callback:^(id observer, NSString *key, id oldValue, id newValue) {
//        NSLog(@"oldValue:%@---newValue:%@",oldValue,newValue);
    }];
    [dog ll_addObserver:self key:@"age" callback:^(id observer, NSString *key, id oldValue, id newValue) {
//        NSLog(@"oldValue:%@---newValue:%@",oldValue,newValue);
    }];
    NSLog(@"%@",object_getClass(dog));//KVO_Dog
    
    dog.name = @"小白";
    dog.name = @"小黑";
    // 移除观察者
    [dog ll_removeObserver:self key:@"name"];
    
    NSLog(@"%@",object_getClass(dog));//KVO_Dog

    dog.age = 5;
    dog.age = 8;
    [dog ll_removeObserver:self key:@"age"];
    NSLog(@"%@",object_getClass(dog));//Dog

    
}


@end
