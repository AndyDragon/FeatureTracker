import React from "react";
import { Body2, Spinner, Title1, makeStyles, shorthands } from "@fluentui/react-components";
import { applicationDescription, supportEmail } from "./config";

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

export default function Support(props: GeneralProps) {
    const { applicationName, versionLocation } = props;
    const styles = useStyles();

    const [isReady, setIsReady] = React.useState(false);

    React.useEffect(() => {
        const doLoad = async () => {
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

    return (
        <div style={{ margin: "50px" }}>
            <Title1>{applicationDescription}</Title1>
            <br /><br />
            <Body2>If you have any issues with the application or require support, please email us at</Body2>
            <br /><br />
            <a style={{marginLeft: 20}} href={`mailto:${supportEmail}?subject=Support request for ${applicationName}`} className={styles.cleanLink}>This email</a>
            <br /><br />
            Be sure to include which platform and version of the application you are using.
        </div>
    );
}