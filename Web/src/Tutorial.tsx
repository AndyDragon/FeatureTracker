import React from "react";
import { Body2, Button, Image, Subtitle2, Title1, makeStyles, shorthands } from "@fluentui/react-components";
import { Link } from "react-router-dom";
import { useParams } from "react-router-dom";
import { Screenshot, tutorialPages } from "./config";

export interface TutorialPageProps {
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
    cleanButtonLink: {
        ...shorthands.textDecoration("none"),
        color: "CornflowerBlue",
        height: "20px",
        verticalAlign: "top",
        "&:hover": {
            ...shorthands.textDecoration("none"),
            color: "LightBlue",
        },
    },
});

export default function Tutorial(props: TutorialPageProps) {
    const styles = useStyles();
    let { page } = useParams();

    const [screenshot, setScreenshot] = React.useState<Screenshot>();

    let index = 0;
    page = page || "step1";
    const pageDetails = tutorialPages[page] || tutorialPages.step1;

    return (
        <div style={{ margin: "50px" }}>
            <Title1>{pageDetails.title}</Title1>
            <div style={{ textAlign: "center"}}>
                <Image alt={pageDetails.title} src={process.env.PUBLIC_URL + "/Tutorial/" + (screenshot || pageDetails.screenshot).name + ".png"} width={(screenshot || pageDetails.screenshot).width} />
            </div>
            <Body2>
                <ul>
                    {pageDetails.bullets.map(bullet => {
                        return (
                            <li>
                                {bullet.text}
                                {bullet.screenshot && screenshot === bullet.screenshot && (
                                    <>&nbsp;&nbsp;<Button className={styles.cleanButtonLink} onClick={() => setScreenshot(undefined)}><span style={{ fontSize: 12, marginRight: "8px" }}>🔍</span>hide</Button></>
                                )}
                                {bullet.screenshot && screenshot !== bullet.screenshot && (
                                    <>&nbsp;&nbsp;<Button className={styles.cleanButtonLink} onClick={() => setScreenshot(bullet.screenshot)}><span style={{ fontSize: 12, marginRight: "8px" }}>🔍</span>show</Button></>
                                )}
                                {bullet.link && (
                                    <>
                                    <Subtitle2 key={"link-" + (index++)} style={{ marginLeft: "40px" }}>➤&nbsp;
                                        <Link className={styles.cleanLink} to={"/tutorial/" + bullet.link} onClick={() => setScreenshot(undefined)}>See details</Link></Subtitle2>
                                        <br />
                                    </>
                                )}
                                {bullet.image && (
                                    <>
                                        <br />
                                        <Image src={process.env.PUBLIC_URL + "/Tutorial/" + bullet.image.name + ".png"} width={bullet.image.width} />
                                    </>
                                )}
                            </li>
                        );
                    })}
                </ul>
            </Body2>
            {pageDetails.previousStep && (
                <>
                    <Subtitle2 key={"link-" + (index++)} style={{ marginLeft: "40px" }}>⏎&nbsp;
                        <Link className={styles.cleanLink} to={"/tutorial/" + pageDetails.previousStep} onClick={() => setScreenshot(undefined)}>Back</Link></Subtitle2>
                    <br />
                </>
            )}
            {pageDetails.nextSteps.map(nextStep => {
                return (
                    <>
                        <Subtitle2 key={"link-" + (index++)} style={{ marginLeft: "40px" }}>➤&nbsp;
                            <Link className={styles.cleanLink} to={"/tutorial/" + nextStep.page} onClick={() => setScreenshot(undefined)}>{nextStep.label}</Link></Subtitle2>
                        <br />
                    </>
                );
            })}
        </div>
    );
}