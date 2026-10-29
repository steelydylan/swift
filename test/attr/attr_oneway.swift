// RUN: %target-swift-frontend -typecheck -verify %s -enable-experimental-feature SendCalls
// REQUIRES: concurrency
// REQUIRES: swift_feature_SendCalls
// REQUIRES: objc_interop

import Foundation

// ==== -----------------------------------------------------------------------
// MARK: '@oneway' is allowed on actor isolated functions

@MainActor @oneway func mainActorFunction() {}
@MainActor @oneway func mainActorAsyncFunction() async {}
@MainActor @oneway func mainActorNeverThrowing() throws(Never) {}
@MainActor @oneway func mainActorGeneric<T>(_ value: T) {}

actor Worker {
  @oneway func isolated() {}
  @oneway func isolatedAsync() async {}
  @MainActor @oneway static func mainActorStaticMethod() {}
}

class IsolatedParameter {
  @oneway func method(_ worker: isolated Worker) {}
}

@MainActor
class MainActorBox {
  @oneway func method() {}
  @oneway class func classMethod() {}
}

@MainActor
struct MainActorValue {
  @oneway func method() {}
}

protocol ActorRequirements: Actor {
  @oneway func requirement()
}

@MainActor
protocol MainActorRequirements {
  @oneway func requirement()
}

extension Worker {
  func local() {
    @oneway func localFunction() {}
  }
}

// ==== -----------------------------------------------------------------------
// MARK: '@oneway' functions must be actor isolated

@oneway func freeFunction() {}
// expected-error@-1:1{{'@oneway' can only be applied to an actor isolated method}}
@oneway func freeAsyncFunction() async {}
// expected-error@-1:1{{'@oneway' can only be applied to an actor isolated method}}
@oneway func generic<T>(_ value: T) {}
// expected-error@-1:1{{'@oneway' can only be applied to an actor isolated method}}

extension Worker {
  @oneway nonisolated func nonisolatedMethod() {}
  // expected-error@-1:3{{'@oneway' can only be applied to an actor isolated method}}
  @oneway static func staticMethod() {}
  // expected-error@-1:3{{'@oneway' can only be applied to an actor isolated method}}
}

class Box {
  @oneway func method() {}
  // expected-error@-1:3{{'@oneway' can only be applied to an actor isolated method}}
  @oneway class func classMethod() {}
  // expected-error@-1:3{{'@oneway' can only be applied to an actor isolated method}}
}

struct Value {
  @oneway func method() {}
  // expected-error@-1:3{{'@oneway' can only be applied to an actor isolated method}}
  @oneway mutating func mutatingMethod() {}
  // expected-error@-1:3{{'@oneway' can only be applied to an actor isolated method}}
}

protocol Requirements {
  @oneway func requirement()
  // expected-error@-1:3{{'@oneway' can only be applied to an actor isolated method}}
}

func local() {
  @oneway func localFunction() {}
  // expected-error@-1:3{{'@oneway' can only be applied to an actor isolated method}}
}

// ==== -----------------------------------------------------------------------
// MARK: '@oneway' functions must return 'Void' and must not throw

@oneway func returnsValue() -> Int { 0 }
// expected-error@-1{{'@oneway' global function 'returnsValue()' must return 'Void'}}

@oneway func throwing() throws {}
// expected-error@-1{{'@oneway' global function 'throwing()' must not throw}}

struct MyError: Error {}
@oneway func typedThrowing() throws(MyError) {}
// expected-error@-1{{'@oneway' global function 'typedThrowing()' must not throw}}

@oneway func rethrowing(_ body: () throws -> Void) rethrows {}
// expected-error@-1{{'@oneway' global function 'rethrowing' must not throw}}

// ==== -----------------------------------------------------------------------
// MARK: '@oneway' is only allowed on 'func' declarations

struct NotFunctions {
  @oneway init() {}
  // expected-error@-1{{@oneway may only be used on 'func' declarations}}

  @oneway subscript(_ i: Int) -> Int { i }
  // expected-error@-1{{@oneway may only be used on 'func' declarations}}

  @oneway var property: Int { 0 }
  // expected-error@-1{{@oneway may only be used on 'func' declarations}}

  var accessor: Int {
    @oneway get { 0 }
    // expected-error@-1{{@oneway may only be used on 'func' declarations}}
  }
}

class WithDeinit {
  @oneway deinit {}
  // expected-error@-1{{@oneway may only be used on 'func' declarations}}
}

// ==== -----------------------------------------------------------------------
// MARK: An '@objc' function cannot be '@oneway'

@MainActor
class ObjCClass: NSObject {
  @objc @oneway func objcMethod() {}
  // expected-error@-1{{'@oneway' must not be used on an '@objc' instance method}}
}

// ==== -----------------------------------------------------------------------
// MARK: Overrides must agree on '@oneway'

@MainActor
class Base {
  func plain() {} // expected-note{{potential overridden instance method 'plain()' here}}
  @oneway func oneway() {} // expected-note{{potential overridden instance method 'oneway()' here}}
}

@MainActor
class Derived: Base {
  @oneway override func plain() {}
  // expected-error@-1{{method does not override any method from its superclass}}

  override func oneway() {}
  // expected-error@-1{{method does not override any method from its superclass}}
}

// ==== -----------------------------------------------------------------------
// MARK: '@oneway' function types

typealias OnewayFn = @oneway @MainActor () -> Void
typealias OnewayAsyncFn = @oneway @MainActor () async -> Void
typealias OnewaySendableFn = @Sendable @oneway @MainActor () -> Void
typealias OnewayNeverThrowingFn = @oneway @MainActor () throws(Never) -> Void
typealias OnewayIsolatedParameterFn = @oneway (isolated Worker) -> Void

typealias OnewayReturning = @oneway @MainActor () -> Int
// expected-error@-1{{'@oneway' function type must return 'Void' and must not throw}}
typealias OnewayThrowing = @oneway @MainActor () throws -> Void
// expected-error@-1{{'@oneway' function type must return 'Void' and must not throw}}
typealias OnewayCFunction = @oneway @convention(c) () -> Void
// expected-error@-1{{'@oneway' cannot be used with '@convention(c)'}}
typealias OnewayNotAFunction = @oneway Int
// expected-error@-1{{'@oneway' only applies to function types}}

// A '@oneway' function type must be isolated to an actor, like a '@oneway'
// function
typealias OnewayNonisolatedFn = @oneway () -> Void
// expected-error@-1:34{{'@oneway' function type must be isolated to an actor}}
typealias OnewayNonisolatedSendableFn = @Sendable @oneway () -> Void
// expected-error@-1:52{{'@oneway' function type must be isolated to an actor}}

// ==== -----------------------------------------------------------------------
// MARK: Conversions: plain to '@oneway' is allowed, '@oneway' to plain is not

func plainFunction() {}

@MainActor
func conversions(_ oneway: @escaping @oneway @MainActor () -> Void,
                 _ plain: @escaping @MainActor () -> Void) {
  let a: @oneway @MainActor () -> Void = plainFunction
  let b: @oneway @MainActor () -> Void = plain
  let c: @oneway @MainActor () -> Void = {}
  let d: @oneway @MainActor () -> Void = mainActorFunction
  let e: @MainActor () -> Void = mainActorFunction
  // expected-error@-1{{cannot convert '@oneway' function of type '@MainActor @oneway () -> ()' to '@MainActor () -> Void', which can be called without 'send'}}
  let f: @MainActor () -> Void = oneway
  // expected-error@-1{{cannot convert '@oneway' function of type '@MainActor @oneway () -> Void' to '@MainActor () -> Void', which can be called without 'send'}}
  // A conversion to a '@oneway' function type which is not isolated
  let g: @oneway () -> Void = plainFunction
  // expected-error@-1:11{{'@oneway' function type must be isolated to an actor}}
  _ = (a, b, c, d, e, f, g)
}
