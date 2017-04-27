//
//  NSObject+LL_KVO.m
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

#import "NSObject+LL_KVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

#define KVOPrefix @"KVO_"
#define ObserverArrayKey @"ObserverArrayKey"

@implementation NSObject (LL_KVO)


- (void)ll_addObserver:(id)observer key:(NSString *)key callback:(LLKVOBlock)callback{
    //1. 通过观察的key获得相应的setter方法
    SEL setterSelector = NSSelectorFromString([self setterForGetter:key]);
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    if (!setterMethod)  return;    //不存在setter方法直接return
    
    //2. 检查对象 isa 指向的类是不是一个 KVO 类。如果不是，新建一个继承原来类的子类，并把 isa 指向这个新建的子类
    Class clazz = object_getClass(self);
    NSString *className = NSStringFromClass(clazz);
    if (![className hasPrefix:KVOPrefix]) {//当前类不是KVO类
        clazz = [self ll_KVOClassWithOriginalClassName:className];
        object_setClass(self, clazz);
    }

    //-------到这里self已经是KVO类了---------
    
    // 3. 检查KVO类是否已重写父类的setter方法，如果没有则为KVO类添加setter方法的实现
    if (![self hasSelector:setterSelector]) {
        const char *types = method_getTypeEncoding(setterMethod);
        
        char *type = method_copyArgumentType(setterMethod, 2);
        if (strcmp(type, "@") == 0) {//对象类型
            class_addMethod(clazz, setterSelector, (IMP)kvo_setter, types);
        }else if (strcmp(type, @encode(long))  == 0) {
            class_addMethod(clazz, setterSelector, (IMP)long_setter, types);
        }else if (strcmp(type, @encode(int)) == 0) {
            class_addMethod(clazz, setterSelector, (IMP)int_setter, types);
        }else if (strcmp(type, @encode(float)) == 0) {
            class_addMethod(clazz, setterSelector, (IMP)float_setter, types);
        }else if (strcmp(type, @encode(double))  == 0) {
            class_addMethod(clazz, setterSelector, (IMP)double_setter, types);
        }else if (strcmp(type, @encode(BOOL)) == 0) {
           class_addMethod(clazz, setterSelector, (IMP)bool_setter, types);
        }
    
    };
    
    // 4. 添加该观察者到观察者列表中
    // 4.1 创建观察者相关信息字典(观察者对象、观察的key、block)
    NSDictionary *infoDic = @{@"observer":observer,@"key":key,@"callback":callback};
    // 4.2 获取关联对象(装着所有观察者的数组)
    NSMutableArray *observers = objc_getAssociatedObject(self, ObserverArrayKey);
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, ObserverArrayKey, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [observers addObject:infoDic];
}




//    动态创建子类
- (Class)ll_KVOClassWithOriginalClassName:(NSString *)className
{
    NSString *kvoClassName = [KVOPrefix stringByAppendingString:className];
    Class kvoClass = NSClassFromString(kvoClassName);//如果类不存在这个方法返回的值为nil
    // 如果kvo class存在则返回
    if (kvoClass) {
        return kvoClass;
    }
    // 如果kvo class不存在, 则创建这个类
    Class originClass = object_getClass(self);
    kvoClass = objc_allocateClassPair(originClass, kvoClassName.UTF8String, 0);
    
    // 修改kvo class方法的实现
    Method clazzMethod = class_getInstanceMethod(kvoClass, @selector(class));
    const char *types = method_getTypeEncoding(clazzMethod);
    class_addMethod(kvoClass, @selector(class), (IMP)ll_class, types);
     // 注册kvo_class
    objc_registerClassPair(kvoClass);
    
    return kvoClass;
    
}


// 重写的class方法的IMP
static Class ll_class(id self, SEL cmd)
{
    //模仿Apple的做法, 欺骗人们这个kvo类还是原类
   return  class_getSuperclass(object_getClass(self));
}



#pragma mark - 私有方法

//根据getter方法名返回setter方法名   name -> Name -> setName:
- (NSString *)setterForGetter:(NSString *)key
{
    // 1. 首字母转换成大写
    unichar c = [key characterAtIndex:0];
    NSString *str = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[NSString stringWithFormat:@"%c", c-32]];
    // 2. 最前增加set, 最后增加:
    NSString *setter = [NSString stringWithFormat:@"set%@:", str];
    return setter;
}

//根据setter方法名返回getter方法名  setName: -> Name -> name
- (NSString *)getterForSetter:(NSString *)key
{
    // 1. 去掉set
    NSRange range = [key rangeOfString:@"set"];
    NSString *subStr1 = [key substringFromIndex:range.location + range.length];
    // 2. 首字母转换成大写
    unichar c = [subStr1 characterAtIndex:0];
    NSString *subStr2 = [subStr1 stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[NSString stringWithFormat:@"%c", c+32]];
    // 3. 去掉最后的:
    NSRange range2 = [subStr2 rangeOfString:@":"];
    NSString *getter = [subStr2 substringToIndex:range2.location];
    return getter;
}

// 判断是否有该方法
- (BOOL)hasSelector:(SEL)selector
{
    Class clazz = object_getClass(self);
    unsigned int methodCount = 0;
    // 获取所有方法列表，遍历比较
    Method* methodList = class_copyMethodList(clazz, &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        SEL thisSelector = method_getName(methodList[i]);
        if (thisSelector == selector) {
            free(methodList);
            return YES;
        }
    }
    
    free(methodList);
    return NO;
}

#pragma mark - 重写各种类型的setter方法，新方法在调用原方法后, 通知每个观察者(调用传入的block)

//对象类型
static void kvo_setter(id self, SEL _cmd, id newValue)
{
    
    // 1.  获取旧值
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = [self getterForSetter:setterName];
    id oldValue = [self valueForKey:getterName];
    
    // 2. 调用父类方法
    struct objc_super superClazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    objc_msgSendSuper(&superClazz, _cmd, newValue);
    
    // 3、获取观察者列表，遍历找出对应的观察者，执行响应的block
    NSMutableArray *observers = objc_getAssociatedObject(self, ObserverArrayKey);
    for (NSDictionary *info in observers) {
        if ([info[@"key"] isEqualToString:getterName]) {
            // 异步调用callback
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                ((LLKVOBlock)info[@"callback"])(info[@"observer"], getterName, oldValue, newValue);
            });
        }
    }
}

//long 类型
static void long_setter(id self, SEL _cmd, long newValue)
{
    
    // 1. 检查getter方法是否存在
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = [self getterForSetter:setterName];
    if (!getterName) {
        
        return;
    }
    
    // 2. 获取旧值
    id oldValue = [self valueForKey:getterName];
    
    // 3. 调用父类方法
    struct objc_super superClazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    objc_msgSendSuper(&superClazz, _cmd, newValue);
    
    // 4、获取观察者列表，遍历找出对应的观察者，执行响应的block
    NSMutableArray *observers = objc_getAssociatedObject(self, ObserverArrayKey);
    for (NSDictionary *info in observers) {
        if ([info[@"key"] isEqualToString:getterName]) {
            // gcd异步调用callback
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                ((LLKVOBlock)info[@"callback"])(info[@"observer"], getterName, oldValue, [NSNumber numberWithLong:newValue]);
            });
        }
    }
}

//int 类型
static void int_setter(id self, SEL _cmd, int newValue)
{
    
    // 1. 检查getter方法是否存在
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = [self getterForSetter:setterName];
    if (!getterName) {
        
        return;
    }
    
    // 2. 获取旧值
    id oldValue = [self valueForKey:getterName];
    
    // 3. 调用父类方法
    struct objc_super superClazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    objc_msgSendSuper(&superClazz, _cmd, newValue);
    
    // 4、获取观察者列表，遍历找出对应的观察者，执行响应的block
    NSMutableArray *observers = objc_getAssociatedObject(self, ObserverArrayKey);
    for (NSDictionary *info in observers) {
        if ([info[@"key"] isEqualToString:getterName]) {
            // gcd异步调用callback
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                ((LLKVOBlock)info[@"callback"])(info[@"observer"], getterName, oldValue, [NSNumber numberWithInt:newValue]);
            });
        }
    }
}

//float 类型
static void float_setter(id self, SEL _cmd, float newValue)
{
    
    // 1. 检查getter方法是否存在
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = [self getterForSetter:setterName];
    if (!getterName) {
        
        return;
    }
    
    // 2. 获取旧值
    id oldValue = [self valueForKey:getterName];
    
    // 3. 调用父类方法
    struct objc_super superClazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    
    objc_msgSendSuper(&superClazz, _cmd, newValue);
    
    
    // 4、获取观察者列表，遍历找出对应的观察者，执行响应的block
    NSMutableArray *observers = objc_getAssociatedObject(self, ObserverArrayKey);
    for (NSDictionary *info in observers) {
        if ([info[@"key"] isEqualToString:getterName]) {
            // gcd异步调用callback
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                ((LLKVOBlock)info[@"callback"])(info[@"observer"], getterName, oldValue, [NSNumber numberWithFloat:newValue]);
            });
        }
    }
}


//double 类型
static void double_setter(id self, SEL _cmd, double newValue)
{
    
    // 1. 检查getter方法是否存在
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = [self getterForSetter:setterName];
    if (!getterName) {
        
        return;
    }
    
    // 2. 获取旧值
    id oldValue = [self valueForKey:getterName];
    
    // 3. 调用父类方法
    struct objc_super superClazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    objc_msgSendSuper(&superClazz, _cmd, newValue);
    
    // 4、获取观察者列表，遍历找出对应的观察者，执行响应的block
    NSMutableArray *observers = objc_getAssociatedObject(self, ObserverArrayKey);
    for (NSDictionary *info in observers) {
        if ([info[@"key"] isEqualToString:getterName]) {
            // gcd异步调用callback
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                ((LLKVOBlock)info[@"callback"])(info[@"observer"], getterName, oldValue, [NSNumber numberWithDouble:newValue]);
            });
        }
    }
}


//bool 类型
static void bool_setter(id self, SEL _cmd, BOOL newValue)
{
    
    // 1. 检查getter方法是否存在
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = [self getterForSetter:setterName];
    if (!getterName) {
        
        return;
    }
    
    // 2. 获取旧值
    id oldValue = [self valueForKey:getterName];
    
    // 3. 调用父类方法
    struct objc_super superClazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    objc_msgSendSuper(&superClazz, _cmd, newValue);
    
    // 4、获取观察者列表，遍历找出对应的观察者，执行响应的block
    NSMutableArray *observers = objc_getAssociatedObject(self, ObserverArrayKey);
    for (NSDictionary *info in observers) {
        if ([info[@"key"] isEqualToString:getterName]) {
            // gcd异步调用callback
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                ((LLKVOBlock)info[@"callback"])(info[@"observer"], getterName, oldValue, [NSNumber numberWithBool:newValue]);
            });
        }
    }
}


// 移除观察者
- (void)ll_removeObserver:(id)observer key:(NSString *)key
{
    NSMutableArray *observers = objc_getAssociatedObject(self, ObserverArrayKey);
    if (!observers) return;

    for (NSDictionary *info in observers) {
        if([info[@"key"] isEqualToString:key]) {
            [observers removeObject:info];
            break;
        }
    }
    // 如果观察者列表count为0，则修改kvo类的isa指针，指向原来的类
    if (observers.count == 0) {
        Class clazz = object_getClass(self);
        NSString *className = NSStringFromClass(clazz);
        Class oriClass =NSClassFromString([className substringFromIndex:KVOPrefix.length]);
        object_setClass(self, oriClass);
    }
}

@end
