import XCTest
@testable import VueFluxReactive

final class SubscribableTests: XCTestCase {
    private final class Object {
        var value = 0
    }
    
    func testScopedSubscribe() {
        var value1 = 0
        var value2 = 0
        var object: Object? = .init()
        
        let subject1 = Subject<Int>()
        let subject2 = Subject<Int>()
        
        subject1.subscribe(scope: object!) { int in
            value1 = int
        }
        
        subject2.subscribe(scope: object!) { int in
            value2 = int
        }
        
        subject1.send(value: 1)
        subject2.send(value: 10)
        
        XCTAssertEqual(value1, 1)
        XCTAssertEqual(value2, 10)
        
        object = nil
        
        subject1.send(value: 2)
        subject2.send(value: 20)
        
        XCTAssertEqual(value1, 1)
        XCTAssertEqual(value2, 10)
    }
    
    func testScopedSubscribeConcurrentAsync() {
        var value = 0
        let queue = DispatchQueue(label: "scoped subscribe loop queue", attributes: .concurrent)
        let group = DispatchGroup()
        
        let subject = Subject<Int>()
        
        for _ in (1...100000) {
            group.enter()
            
            queue.async {
                var object: Object? = .init()
                
                subject.subscribe(scope: object!) { int in
                    value += int
                }
                
                object = nil
                subject.send(value: 1)
                
                group.leave()
            }
        }
        
        _ = group.wait(timeout: .now() + 10)
        
        var object: Object? = .init()
        
        subject.subscribe(scope: object!) { int in
            value += int
        }
        
        subject.send(value: 1)
        
        XCTAssertEqual(value, 1)
        
        object = nil
        
        subject.send(value: 1)
        
        XCTAssertEqual(value, 1)
    }
    
    func testBindWithBinder() {
        var scope: Object? = .init()
        let object = Object()
        
        let subject = Subject<Int>()
        
        subject.bind(scope: scope!, to: .init(target: object, \.value))
        
        subject.send(value: 1)
        
        XCTAssertEqual(object.value, 1)
        
        scope = nil
        
        subject.send(value: 2)
        
        XCTAssertEqual(object.value, 1)
        
        subject.bind(to: .init(target: object, \.value))
        
        subject.send(value: 3)
        
        XCTAssertEqual(object.value, 3)
    }
    
    func testBindWithTargetObject() {
        var scope: Object? = .init()
        let object = Object()
        
        let subject = Subject<Int>()
        
        subject.bind(scope: scope!, to: object, \.value)
        
        subject.send(value: 1)
        
        XCTAssertEqual(object.value, 1)
        
        scope = nil
        
        subject.send(value: 2)
        
        XCTAssertEqual(object.value, 1)
        
        subject.bind(to: object, \.value)
        
        subject.send(value: 3)
        
        XCTAssertEqual(object.value, 3)
    }
}