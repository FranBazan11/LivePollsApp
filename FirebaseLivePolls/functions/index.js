
const fs = require("fs"); 
const jwt = require("jsonwebtoken");
const http2 = require("http2");

const { initializeApp } = require("firebase-admin/app");
const { onDocumentupdated } = require("firebase-functions/v2/firestore");
const { getFirestore } = require("firebase-admin/firestore");
const { event } = require("firebase-functions/v1/analytics");

const teamId = "KJSDFFLDSM" // Your Team ID
const keyId = "KJSDFFLDSM" // Your Key ID que está en el nombre del .p8
const p8FilePath = "./AuthKey_KJSDFFLDSM.p8" // Your .p8 file path

const bundleId = "com.example.app" // Your Bundle ID 

initializeApp();

const db = getFirestore();

// La función utiliza el método onDocumentupdated de Firebase Cloud Functions para escuchar los cambios en los documentos de la colección polls.
exports.myFunction = onDocumentupdated("polls/{pollId}", async (event) => {
    // Obtiene el ID de la encuesta actualizada y los datos actualizados de la encuesta
    const pollId = event.params.pollId;
    const updatedPollData = event.after.data();

    // Imprime los datos actualizados de la encuesta
    console.log("Encuesta actualizada: ", updatedPollData);

    // Obtiene los tokens de push de la colección de tokens de la encuesta actualizada
    const tokensQuerySnapshot = await db.collection(`polls/${pollId}/push_tokens`).get();

    // Crea una matriz de tokens a partir de los documentos de la colección de tokens
    let tokens = [];
    tokensQuerySnapshot.forEach((doc) => {
        tokens.push(doc.data().token);
    });

    // Si no hay tokens, sale de la función
    if (tokens.length == 0) return;

    // Crea un objeto JSON que contiene la carga útil de la notificación push
    const date = new Date();
    const unixTimestamp = Math.floor(date.getTime() / 1000);
    const jsonPayload = {
        "aps": {
            "timestamp": unixTimestamp,
            "event": "update",
            "relevance-score": 100.0,
            "stale-date": unixTimestamp + (60 * 60 * 8),
            "content-state": {
                ...updatedPollData,
                createdAt: null,
                updatedAt: {
                    seconds: updatedPollData.updatedAt.seconds,
                    nanoseconds: updatedPollData.updatedAt.nanoseconds,
                }
            }
        }
    }

    // Envía la notificación push a los tokens
    publishToAPNs(tokens, jsonPayload);
});


function publishToAPNs(tokens, json) {
    // Imprime los tokens y la carga útil que se enviará
    console.log(`Tokens a enviar: ${tokens}, carga útil: ${JSON.stringify(json)}`);

    // Lee la clave privada del archivo y genera un JWT con el ID del equipo y la marca de tiempo actual
    const privateKey = fs.readFileSync(p8FilePath);
    const secondsSinceEpoch = Math.round(Date.now() / 1000);
    const jwtPayload = {
        iss: teamID,
        iat: secondsSinceEpoch
    };

    // Establece una conexión con el servidor APNs y configura un controlador de errores
    const session = http2.connect('https://api.sandbox.push.apple.com:443');
    session.on('error', (err) => {
        console.log("Error de sesión", err);
    });

    // Firma el JWT con la clave privada y recorre cada token para enviar la notificación
    const finalEncryptToken = jwt.sign(jwtPayload, privateKey, {algorithm: 'ES256', keyid: keyID});
    for (const token of tokens) {
        try {
            // Crea un búfer que contiene el JSON de la carga útil
            const payloadBuffer = new Buffer.from(JSON.stringify(json));

            // Envía una solicitud POST al servidor APNs con el token, el encabezado de autorización y otros encabezados requeridos
            const req = session.request(
                {
                    ":method": "POST",
                    ":path": "/3/device/" + token,
                    "authorization": "bearer " + finalEncryptToken,
                    "apns-push-type": "liveactivity",
                    "apns-topic": `${bundleID}.push-type.liveactivity`,
                    "Content-Type": 'application/json',
                    "Content-Length": payloadBuffer.length,
                }
            );

            // Registra el estado de la respuesta
            req.on('response', (headers) => {
                console.log(headers[http2.constants.HTTP2_HEADER_STATUS]);
            });

            let data = '';
            req.setEncoding('utf8');
            req.on('data', (chunk) => data += chunk);

            // Registra los datos de respuesta y cierra la sesión
            req.on('end', () => {
                console.log(`El servidor dice: ${data}`);
                session.close();
            });

            // Envía la carga útil JSON
            req.end(JSON.stringify(json));
        } catch (err) {
            console.error("Error al enviar el token:", err);
        }
    }
}