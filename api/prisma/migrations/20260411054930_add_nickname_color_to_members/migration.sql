-- AlterTable
ALTER TABLE "group_invitations" ADD COLUMN     "color" TEXT,
ADD COLUMN     "nickname" TEXT;

-- AlterTable
ALTER TABLE "share_group_members" ADD COLUMN     "color" TEXT,
ADD COLUMN     "nickname" TEXT;
