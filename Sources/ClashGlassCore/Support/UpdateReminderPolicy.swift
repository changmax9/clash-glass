public enum UpdateReminderPolicy {
    public static func shouldShowCapsule(
        standardDriverWillShowUpdate: Bool,
        updateIsNotDownloaded: Bool
    ) -> Bool {
        !standardDriverWillShowUpdate && updateIsNotDownloaded
    }
}
