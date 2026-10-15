package com.hifi.music.ui.component

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withLink
import androidx.compose.ui.window.DialogProperties
import com.hifi.music.expect.openUrl
import com.hifi.music.ui.theme.seed
import com.hifi.music.ui.theme.typo
import org.jetbrains.compose.resources.painterResource
import org.jetbrains.compose.resources.stringResource
import com.hifi.music.generated.resources.*

@Composable
@ExperimentalMaterial3Api
fun ReviewDialog(
    onDismissRequest: () -> Unit,
    onDoneReview: () -> Unit,
) {
    val uriHandler = LocalUriHandler.current
    AlertDialog(
        properties =
            DialogProperties(
                dismissOnBackPress = false,
                dismissOnClickOutside = false,
            ),
        onDismissRequest = {
            onDismissRequest.invoke()
        },
        confirmButton = {
            TextButton(onClick = {
                onDoneReview.invoke()
                uriHandler.openUri("https://github.com/saferill/HiFi")
            }) {
                Text(
                    stringResource(Res.string.give_a_star),
                    style = typo().bodySmall,
                )
            }
        },
        dismissButton = {
            TextButton(onClick = {
                onDismissRequest.invoke()
            }) {
                Text(
                    stringResource(Res.string.later),
                    style = typo().bodySmall,
                )
            }
        },
        icon = {
            Icon(painterResource(Res.drawable.mono), "App Icon")
        },
        title = {
            Text(
                stringResource(Res.string.enjoying_HiFi),
                style = typo().labelSmall,
            )
        },
        text = {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    buildAnnotatedString {
                        append(stringResource(Res.string.if_you_enjoy_using_HiFi_star_HiFi_on_github_or_leave_a_review_on))
                        withLink(
                            LinkAnnotation.Url(
                                "https://www.producthunt.com/products/HiFi",
                                TextLinkStyles(style = SpanStyle(textDecoration = TextDecoration.Underline, color = seed)),
                            ) {
                                onDoneReview.invoke()
                                onDismissRequest.invoke()
                                uriHandler.openUri("https://www.producthunt.com/products/HiFi")
                            },
                        ) {
                            append(" ProductHunt")
                        }
                        append("\n")
                        // Every locale wraps this in quotes to keep the trailing space, Android style, and Compose
                        // Resources prints them as text. Strip them and add the space here, like " ProductHunt" above.
                        append(stringResource(Res.string.if_you_love_my_work_consider).removeSurrounding("\"").trimEnd() + " ")
                        withLink(
                            LinkAnnotation.Url(
                                "https://buymeacoffee.com/maxrave",
                                TextLinkStyles(style = SpanStyle(textDecoration = TextDecoration.Underline, color = seed)),
                            ) {
                                onDoneReview.invoke()
                                onDismissRequest.invoke()
                                uriHandler.openUri("https://buymeacoffee.com/maxrave")
                            },
                        ) {
                            append(stringResource(Res.string.buying_me_a_coffee))
                        }
                        append("\n")
                        withLink(
                            LinkAnnotation.Url(
                                "https://x.com/maxrave_dev",
                                TextLinkStyles(style = SpanStyle(textDecoration = TextDecoration.Underline, color = seed)),
                            ) {
                                onDoneReview.invoke()
                                onDismissRequest.invoke()
                                // openUrl rather than the uri handler, which throws where no browser answers.
                                runCatching { openUrl("https://x.com/maxrave_dev") }
                            },
                        ) {
                            append(stringResource(Res.string.follow_me_on_x))
                        }
                    },
                    textAlign = TextAlign.Center,
                    style = typo().bodySmall,
                )
            }
        },
    )
}