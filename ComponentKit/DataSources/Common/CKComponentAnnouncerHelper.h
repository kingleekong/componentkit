/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <objc/message.h>
#import <vector>

#import <Foundation/Foundation.h>
#import <ComponentKit/CKComponentAnnouncerBase.h>
#import <ComponentKit/CKComponentAnnouncerBaseInternal.h>

namespace CK {
  namespace Component {
    struct AnnouncerHelper
    {
    private:
      // function to load the current listeners vector in a thread safe way
      static std::shared_ptr<const std::vector<__weak id>> loadListeners(CKComponentAnnouncerBase *self);
    public:
      // 使用参数模板化， typename 在模板中作用类似 class https://zh.cppreference.com/w/cpp/language/parameter_pack
      template<typename... ARGS>
      static void call(CKComponentAnnouncerBase *self, SEL s, ARGS... args) {
        typedef void (*TT)(id self, SEL _cmd, ARGS...); // for floats, etc, we need to use the strong typed versions
        TT objc_msgSendTyped = (TT)(void*)objc_msgSend;
        
        /// 加载 智能指针 shared_ptr 指向的 Vector(装有 Listeners)
        auto frozenListeners = loadListeners(self);
        if (frozenListeners) {
          /// 使用 for 区间遍历 Vector 里面的元素, 一般就是一个 listener，这里如果有俩 listener 会有啥奇怪的事情发生？
          for (id listener : *frozenListeners) {
            // 使用 objc_msgSend 调用函数是需要很大的勇气，不易阅读，这里调用的地方又是如此关键，listener(CKCollectionViewTransactionalDataSource) 调用这些参数
            objc_msgSendTyped(listener, s, args...);
          }
        }
      }
      
      template<typename... ARGS>
      static void callOptional(CKComponentAnnouncerBase *self, SEL s, ARGS... args) {
        typedef void (*TT)(id self, SEL _cmd, ARGS...); // for floats, etc, we need to use the strong typed versions
        TT objc_msgSendTyped = (TT)(void*)objc_msgSend;
        
        auto frozenListeners = loadListeners(self);
        if (frozenListeners) {
          for (id listener : *frozenListeners) {
            if ([listener respondsToSelector:s]) {
              objc_msgSendTyped(listener, s, args...);
            }
          }
        }
      }
      
      static void addListener(CKComponentAnnouncerBase *self, SEL s, id listener);
      
      static void removeListener(CKComponentAnnouncerBase *self, SEL s, id listener);
    };
  }
}
