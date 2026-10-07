import {FieldValue} from "firebase-admin/firestore";
import {onDocumentCreated} from "firebase-functions/v2/firestore";

import {db} from "../infra/firebase";
import {sendToUser} from "../infra/notify";

/** Android notification channel created by the app (MainActivity). */
const CHANNEL_ID = "komentar_guru";
const BODY_MAX = 80;

/**
 * A new teacher comment marks the journal as having unread feedback and
 * notifies the student (docs/04 §2.3).
 *
 * Event delivery is at-least-once, so the comment is stamped with
 * `notifiedAt` in a transaction first; a redelivered event finds the stamp
 * and does not notify twice.
 */
export const onCommentCreated = onDocumentCreated(
  "schools/{schoolId}/programs/{programId}/journals/{date}/comments/{commentId}",
  async (event) => {
    const comment = event.data;
    if (!comment) return;
    const {schoolId, programId, date} = event.params;

    const claimed = await db.runTransaction(async (transaction) => {
      const current = await transaction.get(comment.ref);
      if (!current.exists || current.get("notifiedAt")) return false;
      transaction.update(comment.ref, {notifiedAt: FieldValue.serverTimestamp()});
      return true;
    });
    if (!claimed) return;

    const journalRef = comment.ref.parent.parent;
    const journal = await journalRef?.get();
    if (!journalRef || !journal?.exists) return;

    await journalRef.update({
      hasUnreadTeacherComment: true,
      lastCommentAt: FieldValue.serverTimestamp(),
    });

    const text = (comment.get("text") as string) ?? "";
    await sendToUser(schoolId, journal.get("studentId") as string, {
      notification: {
        title: `Komentar dari ${comment.get("teacherName") as string}`,
        body: text.length > BODY_MAX ? `${text.slice(0, BODY_MAX - 1)}…` : text,
      },
      // Only what the app needs to open the journal; nothing personal.
      data: {type: "comment", programId, date},
      android: {priority: "high", notification: {channelId: CHANNEL_ID}},
    });
  },
);
