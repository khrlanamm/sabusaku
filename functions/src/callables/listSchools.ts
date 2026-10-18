import {onCall} from "firebase-functions/v2/https";

import {CALLABLE_OPTIONS} from "../config";
import {db} from "../infra/firebase";
import {requireSuperadmin} from "../infra/guard";

export interface SchoolEntry {
  id: string;
  name: string;
  status: string;
}

/** Every school, by name, for a superadmin to switch to. */
export const listSchools = onCall(
  CALLABLE_OPTIONS,
  async (request): Promise<{schools: SchoolEntry[]}> => {
    requireSuperadmin(request);
    const snapshot = await db.collection("schools").select("name", "status").get();
    const schools = snapshot.docs
      .map((doc) => ({
        id: doc.id,
        name: (doc.get("name") as string | undefined) ?? doc.id,
        status: (doc.get("status") as string | undefined) ?? "active",
      }))
      .sort((a, b) => a.name.localeCompare(b.name, "id"));
    return {schools};
  },
);
