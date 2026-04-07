-- AlterTable
ALTER TABLE "transactions" ADD COLUMN     "installment_months" INTEGER,
ADD COLUMN     "installment_round" INTEGER,
ADD COLUMN     "is_installment" BOOLEAN NOT NULL DEFAULT false;
