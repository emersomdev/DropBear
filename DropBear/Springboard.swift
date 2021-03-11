import XCTest

extension Springboard.DeleteAppButton {
    public static var `default`: Springboard.DeleteAppButton {
        return .init { application, icon in
            return iOS14.delete(application, icon)
                || iOS13.delete(application, icon)
                || iOS12.delete(application, icon)
        }
    }

    public static var iOS12: Springboard.DeleteAppButton {
        return .init { application, icon in
            // find X
            let iconFrame = icon.frame
            let iconDeleteOffset = CGVector(
                dx: (iconFrame.minX + 3) / application.frame.maxX,
                dy: (iconFrame.minY + 3) / application.frame.maxY
            )

            application
                .coordinate(withNormalizedOffset: iconDeleteOffset)
                .tap()

            return true
        }
    }

    public static var iOS13: Springboard.DeleteAppButton {
        return .init { application, _ in
            let button = application.buttons["Delete App"]

            guard button.waitForExistence(timeout: DropBear.defaultWaitTime) && button.isHittable else { return false }

            button.tap()
            return true
        }
    }

    public static var iOS14: Springboard.DeleteAppButton {
        return .init { application, _ in
            let button = application.buttons["Remove App"]

            guard button.waitForExistence(timeout: DropBear.defaultWaitTime) && button.isHittable else { return false }

            button.tap()

            // iOS 14 has _two_ confirmation dialogs

            let confirmationButton = application.alerts.buttons.allElementsBoundByIndex.first(where: { element in
                element.label.localizedCaseInsensitiveContains("delete")
            })
            guard let confirmation = confirmationButton else { return false }

            let deleteButtonAvailable = confirmation.waitForExistence(timeout: DropBear.defaultWaitTime) && confirmation.isHittable
            guard deleteButtonAvailable else { return false }

            confirmation.tap()

            return true
        }
    }
}

public enum Springboard {
    static let application = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    public static func deleteApp(named name: String, using strategy: DeleteAppButton = .default, required: Bool = false, file: StaticString = #file, line: UInt = #line) {
        let icon = application.icons[name]
        let iconAvailable = icon.waitForExistence(timeout: DropBear.defaultWaitTime) && icon.isHittable

        // Icon isn't there, but we don't need it to be.
        if !required && !iconAvailable { return }

        guard iconAvailable else {
            return XCTFail("Application icon named '\(name)' not found.", file: file, line: line)
        }

        // Long press
        icon.press(forDuration: 1.5)

        // Start deletion
        guard strategy.delete(application, icon) else {
            return XCTFail("Failed to begin the deletion process.", file: file, line: line)
        }

        // Confirm
        let button = application.alerts.buttons.allElementsBoundByIndex.first(where: { element in
            element.label.localizedCaseInsensitiveContains("delete")
        })
        guard let deleteButton = button else {
            return XCTFail("Failed to find the delete button.", file: file, line: line)
        }
        let deleteButtonAvailable = deleteButton.waitForExistence(timeout: DropBear.defaultWaitTime) && deleteButton.isHittable

        guard deleteButtonAvailable else {
            return XCTFail("Failed to confirm the delete.", file: file, line: line)
        }

        deleteButton.tap()
        XCUIDevice.shared.press(.home)
    }
}

extension Springboard {
    public struct DeleteAppButton {
        public typealias Input = (_ application: XCUIApplication, _ icon: XCUIElement) -> Bool

        let delete: Input

        public init(delete: @escaping Input) {
            self.delete = delete
        }
    }
}
