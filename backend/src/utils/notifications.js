const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');
const config = require('../config');
const db = require('../config/database');
const logger = require('../utils/logger');

let messaging = null;

if (config.firebase.projectId && config.firebase.clientEmail && config.firebase.privateKey) {
  try {
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: config.firebase.projectId,
          clientEmail: config.firebase.clientEmail,
          privateKey: config.firebase.privateKey,
        }),
      });
    }

    messaging = admin.messaging();
  } catch (err) {
    logger.warn('Firebase Admin SDK is disabled due to invalid credentials.', { error: err.message });
  }
} else {
  logger.warn('Firebase Admin SDK is disabled because credentials are not configured.');
}

/**
 * Send a push notification to a specific user.
 * Also stores notification record in DB.
 *
 * @param {string} userId
 * @param {{ title: string, body: string, type: string, data?: object }} notification
 */
const sendToUser = async (userId, { title, body, type, data = {} }) => {
  try {
    // Store in DB
    await db.query(
      `INSERT INTO notifications (id, user_id, title, body, type, data)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [uuidv4(), userId, title, body, type, JSON.stringify(data)]
    );

    // Get FCM token
    const userRes = await db.query('SELECT fcm_token FROM users WHERE id = $1', [userId]);
    if (userRes.rows.length === 0 || !userRes.rows[0].fcm_token) return;
    if (!messaging) return;

    const fcmToken = userRes.rows[0].fcm_token;

    const message = {
      token: fcmToken,
      notification: { title, body },
      data: { type, ...Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])) },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'vrisharopan_main',
        },
      },
    };

    const response = await messaging.send(message);
    await db.query('UPDATE notifications SET sent_at = NOW() WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1', [userId]);
    logger.debug('FCM notification sent:', { userId, messageId: response });
  } catch (err) {
    // Do not throw - notification failure should not break the main flow
    logger.error('Failed to send notification:', { userId, error: err.message });
  }
};

/**
 * Send a broadcast notification to multiple users.
 * @param {string[]} userIds
 * @param {{ title: string, body: string, type: string, data?: object }} notification
 */
const sendToMultiple = async (userIds, notification) => {
  await Promise.allSettled(userIds.map((id) => sendToUser(id, notification)));
};

/**
 * Send a broadcast notification to ALL users with FCM tokens.
 * @param {{ title: string, body: string, type: string, data?: object }} notification
 */
const broadcastToAll = async ({ title, body, type, data = {} }) => {
  try {
    // Store single broadcast record (user_id = NULL)
    await db.query(
      `INSERT INTO notifications (id, user_id, title, body, type, data)
       VALUES ($1, NULL, $2, $3, $4, $5)`,
      [uuidv4(), title, body, type, JSON.stringify(data)]
    );

    if (!messaging) return;

    // Get all active user tokens in batches of 500
    const batchSize = 500;
    let offset = 0;

    while (true) {
      const result = await db.query(
        `SELECT fcm_token FROM users
         WHERE fcm_token IS NOT NULL AND status = 'active'
         LIMIT $1 OFFSET $2`,
        [batchSize, offset]
      );

      if (result.rows.length === 0) break;

      const tokens = result.rows.map((r) => r.fcm_token);
      const multicastMessage = {
        tokens,
        notification: { title, body },
        data: { type, ...Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])) },
        android: { priority: 'high' },
      };

      try {
        await messaging.sendEachForMulticast(multicastMessage);
      } catch (err) {
        logger.error('Multicast send error:', err.message);
      }

      if (result.rows.length < batchSize) break;
      offset += batchSize;
    }

    logger.info('Broadcast notification sent.');
  } catch (err) {
    logger.error('Broadcast error:', err.message);
  }
};

module.exports = { sendToUser, sendToMultiple, broadcastToAll };
