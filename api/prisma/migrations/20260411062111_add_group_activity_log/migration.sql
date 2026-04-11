-- CreateTable
CREATE TABLE "group_activity_logs" (
    "id" TEXT NOT NULL,
    "group_id" TEXT NOT NULL,
    "actor_user_id" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "target_email" TEXT,
    "target_nickname" TEXT,
    "memo" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "group_activity_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "group_activity_logs_group_id_idx" ON "group_activity_logs"("group_id");

-- CreateIndex
CREATE INDEX "group_activity_logs_actor_user_id_idx" ON "group_activity_logs"("actor_user_id");

-- AddForeignKey
ALTER TABLE "group_activity_logs" ADD CONSTRAINT "group_activity_logs_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "share_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "group_activity_logs" ADD CONSTRAINT "group_activity_logs_actor_user_id_fkey" FOREIGN KEY ("actor_user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
