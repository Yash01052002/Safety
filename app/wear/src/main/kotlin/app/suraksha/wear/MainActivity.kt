package app.suraksha.wear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Warning
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.ButtonDefaults
import androidx.wear.compose.material.Icon
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.Text
import kotlinx.coroutines.launch

/**
 * Watch face for the companion: one big SOS button. Press-and-confirm keeps an
 * accidental brush from firing; a long-press could be added if desired.
 */
class MainActivity : ComponentActivity() {

    private lateinit var sender: SosSender

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        sender = SosSender(applicationContext)
        setContent { SosScreen(sender) }
    }
}

private enum class Phase { Idle, Sending, Sent, Failed }

@Composable
fun SosScreen(sender: SosSender) {
    val scope = rememberCoroutineScope()
    var phase by remember { mutableStateOf(Phase.Idle) }

    MaterialTheme {
        Column(
            modifier = Modifier.fillMaxSize().padding(8.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Button(
                onClick = {
                    if (phase == Phase.Sending) return@Button
                    phase = Phase.Sending
                    scope.launch {
                        val ok = sender.sendSos()
                        phase = if (ok) Phase.Sent else Phase.Failed
                    }
                },
                modifier = Modifier.size(96.dp),
                colors = ButtonDefaults.primaryButtonColors(
                    backgroundColor = Color(0xFFE53935)
                ),
            ) {
                Icon(
                    imageVector = Icons.Filled.Warning,
                    contentDescription = "Send SOS",
                    tint = Color.White,
                )
            }
            Text(
                text = when (phase) {
                    Phase.Idle -> "SOS"
                    Phase.Sending -> "Sending…"
                    Phase.Sent -> "Alert sent"
                    Phase.Failed -> "Phone unreachable"
                },
                fontWeight = FontWeight.Bold,
                fontSize = 16.sp,
                color = Color.White,
                modifier = Modifier.padding(top = 10.dp),
            )
        }
    }
}
