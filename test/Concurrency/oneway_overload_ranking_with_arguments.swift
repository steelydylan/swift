// RUN: %target-typecheck-verify-swift -target %target-swift-6.2-abi-triple -enable-experimental-feature SendCalls
// RUN: %target-swift-frontend -emit-silgen -target %target-swift-6.2-abi-triple -enable-experimental-feature SendCalls -module-name main %s | %FileCheck %s

// REQUIRES: concurrency
// REQUIRES: swift_feature_SendCalls

// Which of two overloads of an actor method, which differ only in '@oneway'
// (and possibly in 'async'), a call picks: the operand of a 'send' picks the
// '@oneway' overload, any other call picks the one which is not '@oneway'.
// This holds over the preference for an 'async' overload in an async context:
// the operand of a 'send' is type-checked in an async closure, and an
// awaited or plain call may be in an async function.
//
// Each call is checked with an argument as well as without one: with a single
// unlabeled argument the constraint solver favors the overloads which match
// the argument's type exactly, and used to also drop the ones whose 'async'
// did not match the context, so that the other overload was never attempted
// and 'send self.tell(1)' called 'func tell(_:) async'.
//
// Each function makes one call; the operand of a 'send' is emitted in a
// closure ('fU_') of the function

// ==== -----------------------------------------------------------------------
// MARK: '@oneway func f(_:)' and 'func f(_:) async'

actor A1 {
  @oneway func tell(_ n: Int) {}
  func tell(_ n: Int) async {}
  @oneway func zero() {}
  func zero() async {}

  func insideSendArg() async { send self.tell(1) }
  func insideAwaitArg() async { await self.tell(1) }
  func insideSendZero() async { send self.zero() }
  func insideAwaitZero() async { await self.zero() }
}

func a1SendArg(_ a: A1) async { send a.tell(1) }
func a1SendFromSyncArg(_ a: A1) { send a.tell(1) }
func a1AwaitArg(_ a: A1) async { await a.tell(1) }
func a1SendZero(_ a: A1) async { send a.zero() }
func a1SendFromSyncZero(_ a: A1) { send a.zero() }
func a1AwaitZero(_ a: A1) async { await a.zero() }

// ==== -----------------------------------------------------------------------
// MARK: '@oneway func f(_:) async' and 'func f(_:)'

actor A2 {
  @oneway func tell(_ n: Int) async {}
  func tell(_ n: Int) {}
  @oneway func zero() async {}
  func zero() {}

  func insideSendArg() async { send self.tell(1) }
  func insideAwaitArg() async { await self.tell(1) } // expected-warning{{no 'async' operations occur within 'await' expression}}
  func insidePlainArg() async { self.tell(1) }
  func insidePlainSyncArg() { self.tell(1) }
  func insideSendZero() async { send self.zero() }
  func insideAwaitZero() async { await self.zero() } // expected-warning{{no 'async' operations occur within 'await' expression}}
  func insidePlainZero() async { self.zero() }
  func insidePlainSyncZero() { self.zero() }
}

func a2SendArg(_ a: A2) async { send a.tell(1) }
func a2SendFromSyncArg(_ a: A2) { send a.tell(1) }
func a2AwaitArg(_ a: A2) async { await a.tell(1) }
func a2SendZero(_ a: A2) async { send a.zero() }
func a2SendFromSyncZero(_ a: A2) { send a.zero() }
func a2AwaitZero(_ a: A2) async { await a.zero() }

// ==== -----------------------------------------------------------------------
// MARK: '@oneway func f(_:)' and 'func f(_:)'

actor A3 {
  @oneway func tell(_ n: Int) {}
  func tell(_ n: Int) {}
  @oneway func zero() {}
  func zero() {}

  func insideSendArg() async { send self.tell(1) }
  func insideAwaitArg() async { await self.tell(1) } // expected-warning{{no 'async' operations occur within 'await' expression}}
  func insidePlainArg() async { self.tell(1) }
  func insidePlainSyncArg() { self.tell(1) }
  func insideSendZero() async { send self.zero() }
  func insideAwaitZero() async { await self.zero() } // expected-warning{{no 'async' operations occur within 'await' expression}}
  func insidePlainZero() async { self.zero() }
  func insidePlainSyncZero() { self.zero() }
}

func a3SendArg(_ a: A3) async { send a.tell(1) }
func a3SendFromSyncArg(_ a: A3) { send a.tell(1) }
func a3AwaitArg(_ a: A3) async { await a.tell(1) }
func a3SendZero(_ a: A3) async { send a.zero() }
func a3SendFromSyncZero(_ a: A3) { send a.zero() }
func a3AwaitZero(_ a: A3) async { await a.zero() }

// ==== -----------------------------------------------------------------------
// MARK: '@oneway func f(_:) async' and 'func f(_:) async'

actor A4 {
  @oneway func tell(_ n: Int) async {}
  func tell(_ n: Int) async {}
  @oneway func zero() async {}
  func zero() async {}

  func insideSendArg() async { send self.tell(1) }
  func insideAwaitArg() async { await self.tell(1) }
  func insideSendZero() async { send self.zero() }
  func insideAwaitZero() async { await self.zero() }
}

func a4SendArg(_ a: A4) async { send a.tell(1) }
func a4SendFromSyncArg(_ a: A4) { send a.tell(1) }
func a4AwaitArg(_ a: A4) async { await a.tell(1) }
func a4SendZero(_ a: A4) async { send a.zero() }
func a4SendFromSyncZero(_ a: A4) { send a.zero() }
func a4AwaitZero(_ a: A4) async { await a.zero() }


// CHECK-LABEL: sil private [ossa] @$s4main2A1C13insideSendArgyyYaF{{.*}}fU_ :
// CHECK: #A1.tell : (isolated A1) -> @oneway (Int) -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A1C14insideAwaitArgyyYaF :
// CHECK: #A1.tell : (isolated A1) -> (Int) async -> ()
// CHECK-LABEL: sil private [ossa] @$s4main2A1C14insideSendZeroyyYaF{{.*}}fU_ :
// CHECK: #A1.zero : (isolated A1) -> @oneway () -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A1C15insideAwaitZeroyyYaF :
// CHECK: #A1.zero : (isolated A1) -> () async -> ()
// CHECK-LABEL: sil private [ossa] @$s4main9a1SendArgyyAA2A1CYaF{{.*}}fU_ :
// CHECK: #A1.tell : (isolated A1) -> @oneway (Int) -> ()
// CHECK-LABEL: sil private [ossa] @$s4main17a1SendFromSyncArgyyAA2A1CF{{.*}}fU_ :
// CHECK: #A1.tell : (isolated A1) -> @oneway (Int) -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main10a1AwaitArgyyAA2A1CYaF :
// CHECK: #A1.tell : (isolated A1) -> (Int) async -> ()
// CHECK-LABEL: sil private [ossa] @$s4main10a1SendZeroyyAA2A1CYaF{{.*}}fU_ :
// CHECK: #A1.zero : (isolated A1) -> @oneway () -> ()
// CHECK-LABEL: sil private [ossa] @$s4main18a1SendFromSyncZeroyyAA2A1CF{{.*}}fU_ :
// CHECK: #A1.zero : (isolated A1) -> @oneway () -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main11a1AwaitZeroyyAA2A1CYaF :
// CHECK: #A1.zero : (isolated A1) -> () async -> ()
// CHECK-LABEL: sil private [ossa] @$s4main2A2C13insideSendArgyyYaF{{.*}}fU_ :
// CHECK: #A2.tell : (isolated A2) -> @oneway (Int) async -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A2C14insideAwaitArgyyYaF :
// CHECK: #A2.tell : (isolated A2) -> (Int) -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A2C14insidePlainArgyyYaF :
// CHECK: #A2.tell : (isolated A2) -> (Int) -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A2C18insidePlainSyncArgyyF :
// CHECK: #A2.tell : (isolated A2) -> (Int) -> ()
// CHECK-LABEL: sil private [ossa] @$s4main2A2C14insideSendZeroyyYaF{{.*}}fU_ :
// CHECK: #A2.zero : (isolated A2) -> @oneway () async -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A2C15insideAwaitZeroyyYaF :
// CHECK: #A2.zero : (isolated A2) -> () -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A2C15insidePlainZeroyyYaF :
// CHECK: #A2.zero : (isolated A2) -> () -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A2C19insidePlainSyncZeroyyF :
// CHECK: #A2.zero : (isolated A2) -> () -> ()
// CHECK-LABEL: sil private [ossa] @$s4main9a2SendArgyyAA2A2CYaF{{.*}}fU_ :
// CHECK: #A2.tell : (isolated A2) -> @oneway (Int) async -> ()
// CHECK-LABEL: sil private [ossa] @$s4main17a2SendFromSyncArgyyAA2A2CF{{.*}}fU_ :
// CHECK: #A2.tell : (isolated A2) -> @oneway (Int) async -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main10a2AwaitArgyyAA2A2CYaF :
// CHECK: #A2.tell : (isolated A2) -> (Int) -> ()
// CHECK-LABEL: sil private [ossa] @$s4main10a2SendZeroyyAA2A2CYaF{{.*}}fU_ :
// CHECK: #A2.zero : (isolated A2) -> @oneway () async -> ()
// CHECK-LABEL: sil private [ossa] @$s4main18a2SendFromSyncZeroyyAA2A2CF{{.*}}fU_ :
// CHECK: #A2.zero : (isolated A2) -> @oneway () async -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main11a2AwaitZeroyyAA2A2CYaF :
// CHECK: #A2.zero : (isolated A2) -> () -> ()
// CHECK-LABEL: sil private [ossa] @$s4main2A3C13insideSendArgyyYaF{{.*}}fU_ :
// CHECK: #A3.tell : (isolated A3) -> @oneway (Int) -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A3C14insideAwaitArgyyYaF :
// CHECK: #A3.tell : (isolated A3) -> (Int) -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A3C14insidePlainArgyyYaF :
// CHECK: #A3.tell : (isolated A3) -> (Int) -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A3C18insidePlainSyncArgyyF :
// CHECK: #A3.tell : (isolated A3) -> (Int) -> ()
// CHECK-LABEL: sil private [ossa] @$s4main2A3C14insideSendZeroyyYaF{{.*}}fU_ :
// CHECK: #A3.zero : (isolated A3) -> @oneway () -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A3C15insideAwaitZeroyyYaF :
// CHECK: #A3.zero : (isolated A3) -> () -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A3C15insidePlainZeroyyYaF :
// CHECK: #A3.zero : (isolated A3) -> () -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A3C19insidePlainSyncZeroyyF :
// CHECK: #A3.zero : (isolated A3) -> () -> ()
// CHECK-LABEL: sil private [ossa] @$s4main9a3SendArgyyAA2A3CYaF{{.*}}fU_ :
// CHECK: #A3.tell : (isolated A3) -> @oneway (Int) -> ()
// CHECK-LABEL: sil private [ossa] @$s4main17a3SendFromSyncArgyyAA2A3CF{{.*}}fU_ :
// CHECK: #A3.tell : (isolated A3) -> @oneway (Int) -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main10a3AwaitArgyyAA2A3CYaF :
// CHECK: #A3.tell : (isolated A3) -> (Int) -> ()
// CHECK-LABEL: sil private [ossa] @$s4main10a3SendZeroyyAA2A3CYaF{{.*}}fU_ :
// CHECK: #A3.zero : (isolated A3) -> @oneway () -> ()
// CHECK-LABEL: sil private [ossa] @$s4main18a3SendFromSyncZeroyyAA2A3CF{{.*}}fU_ :
// CHECK: #A3.zero : (isolated A3) -> @oneway () -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main11a3AwaitZeroyyAA2A3CYaF :
// CHECK: #A3.zero : (isolated A3) -> () -> ()
// CHECK-LABEL: sil private [ossa] @$s4main2A4C13insideSendArgyyYaF{{.*}}fU_ :
// CHECK: #A4.tell : (isolated A4) -> @oneway (Int) async -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A4C14insideAwaitArgyyYaF :
// CHECK: #A4.tell : (isolated A4) -> (Int) async -> ()
// CHECK-LABEL: sil private [ossa] @$s4main2A4C14insideSendZeroyyYaF{{.*}}fU_ :
// CHECK: #A4.zero : (isolated A4) -> @oneway () async -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main2A4C15insideAwaitZeroyyYaF :
// CHECK: #A4.zero : (isolated A4) -> () async -> ()
// CHECK-LABEL: sil private [ossa] @$s4main9a4SendArgyyAA2A4CYaF{{.*}}fU_ :
// CHECK: #A4.tell : (isolated A4) -> @oneway (Int) async -> ()
// CHECK-LABEL: sil private [ossa] @$s4main17a4SendFromSyncArgyyAA2A4CF{{.*}}fU_ :
// CHECK: #A4.tell : (isolated A4) -> @oneway (Int) async -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main10a4AwaitArgyyAA2A4CYaF :
// CHECK: #A4.tell : (isolated A4) -> (Int) async -> ()
// CHECK-LABEL: sil private [ossa] @$s4main10a4SendZeroyyAA2A4CYaF{{.*}}fU_ :
// CHECK: #A4.zero : (isolated A4) -> @oneway () async -> ()
// CHECK-LABEL: sil private [ossa] @$s4main18a4SendFromSyncZeroyyAA2A4CF{{.*}}fU_ :
// CHECK: #A4.zero : (isolated A4) -> @oneway () async -> ()
// CHECK-LABEL: sil hidden [ossa] @$s4main11a4AwaitZeroyyAA2A4CYaF :
// CHECK: #A4.zero : (isolated A4) -> () async -> ()
