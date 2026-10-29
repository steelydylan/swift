// RUN: %target-swift-frontend -emit-ir -g %s -module-name M -enable-experimental-feature SendCalls -target %target-swift-5.1-abi-triple -o - | %FileCheck %s

// REQUIRES: concurrency
// REQUIRES: swift_feature_SendCalls

// A '@oneway' function type must be isolated to an actor, so the types here
// are '@MainActor' or have an 'isolated' parameter.
//
// '@oneway' is kept in the debugger mangling ('Yo'), so debug info
// type reconstruction must bring '@oneway' back. With an asserts compiler
// IRGenDebugInfo round-trips every emitted type and aborts on a mismatch.

public typealias SendFn = @oneway @MainActor () -> Void

public struct Holder {
  public var f: @oneway @MainActor () -> Void
  public var g: SendFn?
  public var h: @oneway @MainActor (Int) async -> Void
  public var i: @oneway (isolated Worker, Int) -> Void
}

public struct Box<T> {
  public var value: T
}

public actor Worker {
  @oneway public func work(_ value: Int) {}
}

public func nested(
  _ arr: [@oneway @MainActor (Int) -> Void],
  _ opt: SendFn?,
  _ box: Box<SendFn>,
  _ holder: Holder,
  _ worker: Worker
) {
  let tuple: (Int, @oneway @Sendable @MainActor () -> Void)? = nil
  let copy = arr
  let methods = [Worker.work]
  _ = (copy, tuple, opt, box, holder, methods)
}

public func local(
  _ fn: @escaping @oneway @MainActor () -> Void,
  _ isolatedFn: @escaping @oneway (isolated Worker, Int) -> Void
) {
  let f: @oneway @MainActor () -> Void = fn
  let g: @oneway (isolated Worker, Int) -> Void = isolatedFn
  _ = (f, g)
}

public var globalArr: [@oneway @MainActor (Int) -> Void] = []

// CHECK-DAG: !DICompositeType({{.*}}name: "$syyYoScMYccD"
// CHECK-DAG: !DICompositeType({{.*}}name: "$sySiYoScMYccD"
// CHECK-DAG: !DICompositeType({{.*}}name: "$sSayySiYoScMYccGD"
// CHECK-DAG: !DICompositeType({{.*}}name: "$sSayySiYoc1M6WorkerCYicGD"
