//
//  File.swift
//  
//
//  Created by Sergey Kazakov on 06.06.2022.
//

import XCTest
@testable import PureduxUIKit
import PureduxStore

final class VCWithStoreWithAlwaysEqualDeduplicationVCTests: XCTestCase {
    let timeout: TimeInterval = 4

    let state = TestAppState(
        subStateWithTitle: SubStateWithTitle(title: ""),
        subStateWithIndex: SubStateWithIndex(index: 0)
    )

    lazy var rootStore: RootStore = {
        RootStore<TestAppState, Action>(initialState: state) { state, action in
            state.reduce(action)
        }
    }()

    lazy var store: Store = {
        rootStore.store()
    }()


    func setupVCForTests(vcUpdatedExpectation: XCTestExpectation) -> StubViewController {
        let vc = StubViewController()

        vc.with(
            store: store,
            props: { state, store in
                .init(title: state.subStateWithTitle.title)
            },
            removeStateDuplicates: .alwaysEqual
        )

        vc.didSetProps = {
            vcUpdatedExpectation.fulfill()
        }
        return vc
    }
}

extension VCWithStoreWithAlwaysEqualDeduplicationVCTests {
    func test_WhenManyNonMutatingActionsAndNotSubscribedAndDeduplicationAlwaysEqual_ThenVCNotUpdated() {
        let actionsCount = 1000
        let expectation = expectation(description: "propsEvaluated")
        expectation.isInverted = true

        let _ = setupVCForTests(vcUpdatedExpectation: expectation)

        (0..<actionsCount).forEach { _ in
            store.dispatch(NonMutatingStateAction())
        }

        waitForExpectations(timeout: timeout)
    }

    func test_WhenManyNonMutatingActionsDeduplicationAlwaysEqual_ThenVCUpdatedOnce() {
        let actionsCount = 1000
        let expectation = expectation(description: "propsEvaluated")
        expectation.expectedFulfillmentCount = 1

        let vc = setupVCForTests(vcUpdatedExpectation: expectation)
        vc.viewDidLoad()

        (0..<actionsCount).forEach { _ in
            store.dispatch(NonMutatingStateAction())
        }

        waitForExpectations(timeout: timeout)
    }

    func test_WhenManyMutatingActionsAndDeduplicationAlwaysEqual_ThenVCUpdatedOnce() {
        let actionsCount = 1000
        let expectation = expectation(description: "propsEvaluated")
        expectation.expectedFulfillmentCount = 1

        let vc = setupVCForTests(vcUpdatedExpectation: expectation)
        vc.viewDidLoad()

        (0..<actionsCount).forEach {
            store.dispatch(UpdateIndex(index: $0))
        }

        waitForExpectations(timeout: timeout)
    }
}

extension VCWithStoreWithAlwaysEqualDeduplicationVCTests {

    static var allTests = [
        ("test_WhenManyNonMutatingActionsAndNotSubscribedAndDeduplicationAlwaysEqual_ThenVCNotUpdated",
         test_WhenManyNonMutatingActionsAndNotSubscribedAndDeduplicationAlwaysEqual_ThenVCNotUpdated),

        ("test_WhenManyNonMutatingActionsDeduplicationAlwaysEqual_ThenVCUpdatedOnce",
         test_WhenManyNonMutatingActionsDeduplicationAlwaysEqual_ThenVCUpdatedOnce),

        ("test_WhenManyMutatingActionsAndDeduplicationAlwaysEqual_ThenVCUpdatedOnce",
         test_WhenManyMutatingActionsAndDeduplicationAlwaysEqual_ThenVCUpdatedOnce)
    ]
}