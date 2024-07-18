import React from "react";
import { Version, readVersion } from "./version";
import { Link, Spinner, Subtitle1, Subtitle2, makeStyles, shorthands } from "@fluentui/react-components";
import { Platform, links, platformString } from "./config";
import { Link as RouterLink } from "react-router-dom";

export interface GeneralProps {
    readonly applicationName: string;
    readonly platform: Platform;
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

export default function General(props: GeneralProps) {
    const { applicationName, platform, versionLocation } = props;
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

    const currentVersion = version?.[platform]?.current;
    if (!currentVersion) {
        return (
            <div style={{ margin: "10px" }}>
                There is currently no version available for {platformString[platform]}. Check back at a later date for more information.
            </div>
        );
    }

    let index = 0;

    return (
        <div style={{ margin: "10px" }}>
            <Subtitle1>{applicationName} v{currentVersion} for {platformString[platform]} is available for installation now.</Subtitle1><br /><br />
            {links[platform]?.actions.map(flavor => {
                const location = "https://vero.andydragon.com/app/" + links[platform]?.location(currentVersion, flavor.suffix);
                return (
                    <>
                        <Subtitle2 key={"link-" + (index++)} style={{ marginLeft: "40px" }}>You can {flavor.action} the <Link target={flavor.target} href={location}>{flavor.name} version here</Link></Subtitle2>
                        <br /><br />
                    </>
                );
            })}
            {(platform === "macOS" && version?.["macOS_v2"]?.current) &&
                <Subtitle1 style={{ display: "block", marginTop: "60px" }}><span style={{ color: "red" }}>NEW!</span> There is a new V2 version available for {platformString[platform]}. You can download it <RouterLink className={styles.cleanLink} to="/macInstall_v2">from here</RouterLink></Subtitle1>
            }
        </div>
    );
}