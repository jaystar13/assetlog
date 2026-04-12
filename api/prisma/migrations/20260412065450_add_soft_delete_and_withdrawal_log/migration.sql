-- AlterTable
ALTER TABLE "users" ADD COLUMN     "deleted_at" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "withdrawal_logs" (
    "id" TEXT NOT NULL,
    "email_hash" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "reason" TEXT,
    "withdrawn_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "purge_after" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "withdrawal_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "withdrawal_logs_email_hash_idx" ON "withdrawal_logs"("email_hash");
