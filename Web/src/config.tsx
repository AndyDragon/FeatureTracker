export const applicationName = "Feature Tracker";
export const applicationDescription = "Feature Tracker is a small utility app to track Vero features.";
export const applicationDetails = (
    <>
        This utility lets you track your snap hub features on Vero and will calculate what your membership level should be
        based on the feature count and pages with a feature count. This includes multiple point features and challenges.
    </>
);
export const showMacScreenshot = true
export const macScreenshotWidth = 1024;
export const macScreenshotHeight = 630;
export const showWindowsScreenshot = true
export const windowsScreenshotWidth = 940;
export const windowsScreenshotHeight = 580;

export const deploymentWebLocation = "/app/featuretracker";

export const versionLocation = "featuretracker/version.json";

export const enum PlatformLocation {
    DoNotShow,
    AppPortal,
    AppStore,
}

export const showMacInfo: PlatformLocation = PlatformLocation.AppStore;
export const macAppStoreLocation = "https://apps.apple.com/us/app/feature-tracker/id6477620474";
export const macReleaseNotesLocation = "releaseNotes-mac.json";

export const showIosInfo: PlatformLocation = PlatformLocation.DoNotShow;
export const iosAppStoreLocation = "TODO";
export const iosReleaseNotesLocation = "releaseNotes-ios.json";

export const showWindowsInfo: PlatformLocation = PlatformLocation.AppStore;
export const windowsAppStoreLocation = "https://apps.microsoft.com/store/detail/9N8KQXBLW9PJ";
export const windowsReleaseNotesLocation = "releaseNotes-windows.json";

export const showAndroidInfo: PlatformLocation = PlatformLocation.DoNotShow;
export const androidInstallerLocation = "TODO";
export const androidReleaseNotesLocation = "releaseNotes-android.json";

export const supportEmail = "andydragon@live.com";

export const hasTutorial = false;

export type Platform = "macOS" | "windows" | "iOS" | "android";

export const platformString: Record<Platform, string> = {
    macOS: "macOS",
    windows: "Windows",
    iOS: "iPhone / iPad",
    android: "Android",
}

export interface Links {
    readonly useAppStore?: true;
    readonly location: (version: string, flavorSuffix: string) => string;
    readonly actions: {
        readonly action: string;
        readonly target: string;
        readonly suffix: string;
    }[];
}

export const links: Record<Platform, Links | undefined> = {
    macOS: {
        useAppStore: true,
        location: (_version, _suffix) => macAppStoreLocation,
        actions: [
            {
                action: "install from Apple app store",
                target: "_blank",
                suffix: "",
            }
        ]
    },
    iOS: {
        useAppStore: true,
        location: (_version, _suffix) => iosAppStoreLocation,
        actions: [
            {
                action: "install from Apple app store",
                target: "_blank",
                suffix: "",
            }
        ]
    },
    windows: {
        useAppStore: true,
        location: (_version, _suffix) => windowsAppStoreLocation,
        actions: [
            {
                action: "install from Microsoft store",
                target: "_blank",
                suffix: "",
            }
        ]
    },
    android: {
        useAppStore: true,
        location: (_version, _suffix) => androidInstallerLocation,
        actions: [
            {
                action: "install from Google Play store",
                target: "_blank",
                suffix: "",
            }
        ]
    },
};

export interface NextStep {
    readonly label: string;
    readonly page: string;
}

export interface Screenshot {
    readonly name: string;
    readonly width?: string;
}

export interface Bullet {
    readonly text: string;
    readonly image?: Screenshot;
    readonly screenshot?: Screenshot;
    readonly link?: string;
}

export interface PageStep {
    readonly screenshot: Screenshot;
    readonly title: string;
    readonly bullets: Bullet[];
    readonly previousStep?: string;
    readonly nextSteps: NextStep[];
}

export const tutorialPages: Record<string, PageStep> = {
};
