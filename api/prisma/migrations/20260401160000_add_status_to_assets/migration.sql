-- AlterTable
ALTER TABLE "assets" ADD COLUMN "status" TEXT NOT NULL DEFAULT 'active',
ADD COLUMN "closed_at" TIMESTAMP(3);
