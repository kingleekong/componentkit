/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKComponentAnnouncerHelper.h"

namespace CK {

  // used by enumerating part of the code to get currently listeners
  std::shared_ptr<const std::vector<__weak id>> Component::AnnouncerHelper::loadListeners(CKComponentAnnouncerBase *self) {
    return self->_listenerVector;
  }

  // used by the add/remove code to store the listeners.
  /// 用一个 OC 的对象 CKComponentAnnouncerBase 持有这个指向 Vector(装有listener) 的智能指针
  static void storeListeners(CKComponentAnnouncerBase *self, std::shared_ptr<const std::vector<__weak id>> newListeners) {
    self->_listenerVector = newListeners;
  }

  static std::shared_ptr<std::vector<__weak id>> copyVectorRemovingNils(const std::vector<__weak id> &vec) {
    auto res = std::make_shared<std::vector<__weak id>>();
    res->reserve(vec.size() + 1); // most of the time, we're adding an element, and
    std::copy_if (vec.begin(), vec.end(), std::back_inserter(*res), [](id listener){return listener != nil;});
    return res;
  }

  static std::shared_ptr<std::vector<__weak id>> copyVectorRemovingNilsAndElement(const std::vector<__weak id> &vec,
                                                                                  const id &elementToRemove) {
    auto res = std::make_shared<std::vector<__weak id>>();
    if (vec.size() > 2) {
      res->reserve(vec.size() - 1);
    }
    std::copy_if (vec.begin(), vec.end(), std::back_inserter(*res), [&elementToRemove](id listener){
      return listener != nil && listener != elementToRemove;
    });
    return res;
  }

  void Component::AnnouncerHelper::addListener(CKComponentAnnouncerBase *self, SEL s, id listener) {
      /// self 是入参 🤣
    if (self->_listenerVector) {
        /// std::中 find 函数 eg: https://en.cppreference.com/w/cpp/algorithm/find#Example
      if (std::find(self->_listenerVector->begin(), self->_listenerVector->end(), listener) != self->_listenerVector->end()) {
        // Multiple notifications to the same listener are not allowed.
        return;
      }
      // copy the old vector
      auto newListeners = copyVectorRemovingNils(*(self->_listenerVector));
      // add the new listener
      newListeners->push_back(listener);
      storeListeners(self, newListeners);
    } else {
      // create a new empty listener vector
      /// 使用 make_str 创建一个智能指针指向一个 Vecor 容器
      auto newListeners = std::make_shared<std::vector<__weak id>>();
      // add the new listener
      /// 把 listener 压栈
      newListeners->push_back(listener);
        
      storeListeners(self, newListeners);
    }
  }
  void Component::AnnouncerHelper::removeListener(CKComponentAnnouncerBase *self, SEL s, id listener) {
    // if we don't have anything in the vector, do nothing
    if (!self->_listenerVector) {
      return;
    }
    // copy the vector removing nils and the listener if it exists. If we have multiple copies of the listener
    //   in there, we remove all copies
    auto newListeners = copyVectorRemovingNilsAndElement(*(self->_listenerVector), listener);
    storeListeners(self, newListeners);
  }
}
