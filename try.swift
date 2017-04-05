
typealias TryEmpty = Try<()>

enum Try<T> {
    case success(T)
    case failure(Error)

    init(_ factory: () throws -> T) {
        do {
            self = .success(try factory())
        } catch {
            self = .failure(error)
        }
    }

    init(_ value: T) {
        self = .success(value)
    }

    init(_ error: Error) {
        self = .failure(error)
    }

    init(_ optional: T?, else factory: @autoclosure () -> Error) {
        if let t = optional {
            self = .success(t)
        } else {
            self = .failure(factory())
        }
    }

    func flatMap<U>(_ transform: (T) -> Try<U>) -> Try<U> {
        switch self {
        case .success(let t):
            return transform(t)
        case .failure(let error):
            return .failure(error)
        }
    }

}

extension Try {

    var isSuccess: Bool {
        switch self {
        case .success(_):
            return true
        case .failure(_):
            return false
        }
    }

    var isFailure: Bool {
        switch self {
        case .success(_):
            return false
        case .failure(_):
            return true
        }
    }

    var value: T? {
        switch self {
        case .success(let t):
            return t
        case .failure(_):
            return nil
        }
    }

    var error: Error? {
        switch self {
        case .success(_):
            return nil
        case .failure(let error):
            return error
        }
    }

}

extension Try {

    func map<U>(_ transform: (T) throws -> U) -> Try<U> {
        switch self {
        case .success(let t):
            do {
                return .success(try transform(t))
            } catch {
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }


    func flatMap<U>(_ transform: (T) throws -> U) -> Try<U> {
        return map(transform)
    }

    func zip<U>(_ other: @autoclosure () -> Try<U>) -> Try<(T, U)> {
        return flatMap { t in
            other().map { u in
                return (t, u)
            }
        }
    }

    func zip<U, R>(_ other: @autoclosure () -> Try<U>, _ zipper: (T, U) -> R) -> Try<R> {
        return flatMap { t in
            other().map { u in
                return zipper(t, u)
            }
        }
    }

    @discardableResult func perform(_ block: (T) throws -> Void) -> Try<T> {
        switch self {
        case .success(let t):
            do {
                try block(t)
            } catch {
                return .failure(error)
            }
        default:
            break
        }
        return self
    }

    func fallback(_ recovery: @autoclosure () -> Try<T>) -> Try<T> {
        switch self {
        case .success(_):
            return self
        case .failure(_):
            return recovery()
        }
    }

}
