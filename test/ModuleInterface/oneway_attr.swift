// RUN: %empty-directory(%t)

// RUN: %target-swift-frontend -emit-module -parse-as-library -language-mode 5 -enable-library-evolution -enable-experimental-feature SendCalls -module-name OnewayLib -emit-module-interface-path %t/OnewayLib.swiftinterface -emit-module-path %t/OnewayLib.swiftmodule %s
// RUN: %target-swift-frontend -typecheck-module-from-interface %t/OnewayLib.swiftinterface -module-name OnewayLib
// RUN: %FileCheck %s --input-file %t/OnewayLib.swiftinterface

// Both the module and the module interface keep '@oneway', so a client
// still has to call the functions with 'send'
// RUN: %target-swift-frontend -typecheck -verify -disable-availability-checking -enable-experimental-feature SendCalls -D CLIENT -I %t %s
// RUN: rm %t/OnewayLib.swiftmodule
// RUN: %target-swift-frontend -typecheck -verify -disable-availability-checking -enable-experimental-feature SendCalls -D CLIENT -I %t %s

// REQUIRES: concurrency
// REQUIRES: swift_feature_SendCalls

#if !CLIENT

// CHECK: public actor Worker {
public actor Worker {
  public init() {}

  // CHECK: #if compiler(>=5.3) && $SendCalls
  // CHECK-NEXT: @oneway public func tick()
  // CHECK-NEXT: #endif
  @oneway public func tick() {}

  // CHECK: #if compiler(>=5.3) && $SendCalls
  // CHECK-NEXT: @oneway public func log(_ line: Swift::String) async
  // CHECK-NEXT: #endif
  @oneway public func log(_ line: String) async {}

  // An overload which is not '@oneway'
  // CHECK: public func tick() async
  public func tick() async {}
}

// CHECK: #if compiler(>=5.3) && $SendCalls
// CHECK-NEXT: @_Concurrency::MainActor @oneway public func ping()
// CHECK-NEXT: #endif
@MainActor @oneway public func ping() {}

// CHECK: #if compiler(>=5.3) && $SendCalls
// CHECK-NEXT: public typealias Callback = @_Concurrency::MainActor @oneway () -> Swift::Void
// CHECK-NEXT: #endif
public typealias Callback = @oneway @MainActor () -> Void

// CHECK: #if compiler(>=5.3) && $SendCalls
// CHECK-NEXT: public func register(_ callback: @escaping @_Concurrency::MainActor @oneway () -> Swift::Void)
// CHECK-NEXT: #endif
public func register(_ callback: @escaping @oneway @MainActor () -> Void) {}

#else

import OnewayLib

@MainActor
func client(_ worker: Worker) async {
  send worker.tick()
  send worker.log("line")
  send ping()
  await worker.tick()

  ping()

  let callback: Callback = ping
  let plain: @MainActor () -> Void = callback
  // expected-error@-1{{cannot convert '@oneway' function of type '@MainActor @oneway () -> Void' to '@MainActor () -> Void', which can be called without 'send'}}
  _ = plain
}

#endif
