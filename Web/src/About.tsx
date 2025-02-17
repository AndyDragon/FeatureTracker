import React from "react";
import { Version, readVersion } from "./version";
import { Body2, Spinner, Image, Subtitle2, Title1, makeStyles, shorthands } from "@fluentui/react-components";
import {
    applicationDescription,
    applicationDetails,
    links,
    macScreenshotHeight,
    macScreenshotWidth,
    Platform,
    PlatformLocation,
    platformString,
    showAndroidInfo,
    showIosInfo,
    showMacInfo,
    showMacScreenshot,
    showWindowsInfo,
    showWindowsScreenshot,
    windowsScreenshotHeight,
    windowsScreenshotWidth,
} from "./config";
import { Link } from "react-router-dom";

export interface GeneralProps {
    readonly applicationName: string;
    readonly versionLocation: string;
}

const useStyles = makeStyles({
    container: {
        "> div": { ...shorthands.padding("50px") }
    },
    cleanLink: {
        ...shorthands.textDecoration("none"),
        color: "CornflowerBlue",
        "&:hover": {
            ...shorthands.textDecoration("underline"),
            color: "LightBlue",
        },
    },
});

export default function About(props: GeneralProps) {
    const { applicationName, versionLocation } = props;
    const styles = useStyles();

    const [isReady, setIsReady] = React.useState(false);
    const [version, setVersion] = React.useState<Version | undefined>(undefined);

    React.useEffect(() => {
        const doLoad = async () => {
            setVersion(await readVersion(versionLocation));
            setTimeout(() => {
                setIsReady(true);
            }, 200);
        };
        doLoad();
    }, [versionLocation])

    if (!isReady) {
        return (
            <div className={styles.container}><Spinner appearance="primary" label="Loading..." /></div>
        );
    }

    let index = 0;

    const platforms: { platform: Platform; installLocation: string }[] = [];
    (links["macOS"]?.useAppStore || version?.["macOS"]?.current) && (showMacInfo !== PlatformLocation.DoNotShow) && platforms.push({ platform: "macOS", installLocation: "./macInstall" });
    (links["iOS"]?.useAppStore || version?.["iOS"]?.current) && (showIosInfo !== PlatformLocation.DoNotShow) && platforms.push({ platform: "iOS", installLocation: "./iosInstall" });
    (links["windows"]?.useAppStore || version?.["windows"]?.current) && (showWindowsInfo !== PlatformLocation.DoNotShow) && platforms.push({ platform: "windows", installLocation: "./windowsInstall" });
    (links["android"]?.useAppStore || version?.["android"]?.current) && (showAndroidInfo !== PlatformLocation.DoNotShow) && platforms.push({ platform: "android", installLocation: "./androidInstall" });
    return (
        <div style={{ margin: "50px" }}>
            <Title1>{applicationDescription}</Title1>
            <br /><br />
            <Body2>{applicationDetails}</Body2>
            <br /><br />
            <div style={{ textAlign: "center" }}>
                {showMacScreenshot && (<Image alt="macOS Screenshot" src={process.env.PUBLIC_URL + "/MacOS.png"} width={macScreenshotWidth} height={macScreenshotHeight} />)}
                <br />
                {showWindowsScreenshot && (<Image alt="Windows Screenshot" src={process.env.PUBLIC_URL + "/Windows.png"} width={windowsScreenshotWidth} height={windowsScreenshotHeight} />)}
            </div>
            <br /><br />
            <Subtitle2>{applicationName} is currently available for:</Subtitle2>
            <br /><br />
            {platforms.map(platform => {
                const currentVersion = links[platform.platform]?.useAppStore ? "" : " v" + version?.[platform.platform]?.current || "";
                return (
                    <>
                        <Subtitle2 key={"link-" + (index++)} style={{ marginLeft: "40px" }}>&#x27A4; {platformString[platform.platform]}{currentVersion} available-
                            <Link className={styles.cleanLink} to={platform.installLocation}>more information here</Link></Subtitle2>
                        <br /><br />
                    </>
                );
            })}
        </div>
    );
}