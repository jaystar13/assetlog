-- AlterTable
ALTER TABLE "transactions" ADD COLUMN     "target_month" TEXT;

-- CreateIndex
CREATE INDEX "transactions_user_id_target_month_idx" ON "transactions"("user_id", "target_month");
