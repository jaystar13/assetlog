import '../models/models.dart';

class CashflowRepository {
  List<Transaction> getTransactions() => [
        Transaction(
          id: '1',
          type: TransactionType.income,
          name: '월급',
          amount: 5000000,
          date: '2026-03-01',
          category: 'Salary',
          subCategory: '직장 급여',
          editedBy: '나',
        ),
        Transaction(
          id: '2',
          type: TransactionType.expense,
          name: '식료품 쇼핑',
          amount: 250000,
          date: '2026-03-05',
          category: 'Essential',
          subCategory: 'Groceries',
          editedBy: '김영수',
        ),
        Transaction(
          id: '3',
          type: TransactionType.expense,
          name: '레스토랑',
          amount: 120000,
          date: '2026-03-10',
          category: 'Optional',
          subCategory: 'Dining Out',
          editedBy: '나',
        ),
        Transaction(
          id: '4',
          type: TransactionType.income,
          name: '배당금',
          amount: 350000,
          date: '2026-03-12',
          category: 'Financial',
          subCategory: '투자 수익',
          editedBy: '박지현',
        ),
        Transaction(
          id: '5',
          type: TransactionType.expense,
          name: '전기세',
          amount: 85000,
          date: '2026-03-14',
          category: 'Living',
          subCategory: 'Utilities',
          editedBy: '나',
        ),
      ];

  List<Transaction> getLastMonthTransactions() => [
        Transaction(
          id: 'lm-1',
          type: TransactionType.income,
          name: '월급',
          amount: 4800000,
          date: '2026-02-01',
          category: 'Salary',
          subCategory: '직장 급여',
        ),
        Transaction(
          id: 'lm-2',
          type: TransactionType.expense,
          name: '식료품 쇼핑',
          amount: 230000,
          date: '2026-02-05',
          category: 'Essential',
          subCategory: 'Groceries',
        ),
        Transaction(
          id: 'lm-3',
          type: TransactionType.expense,
          name: '레스토랑',
          amount: 150000,
          date: '2026-02-10',
          category: 'Optional',
          subCategory: 'Dining Out',
        ),
        Transaction(
          id: 'lm-4',
          type: TransactionType.expense,
          name: '전기세',
          amount: 92000,
          date: '2026-02-14',
          category: 'Living',
          subCategory: 'Utilities',
        ),
      ];

  int getLastMonthIncome() => 4800000;
  int getLastMonthExpense() => 3900000;

  List<CardCompany> getCardCompanies() => const [
        CardCompany(id: 'shinhan', name: '신한카드', format: 'Excel(.xls)', enabled: true),
        CardCompany(id: 'kb', name: 'KB국민카드', format: 'Excel(.xlsx)', enabled: true),
        CardCompany(id: 'hyundai', name: '현대카드', format: 'Excel(.xlsx)', enabled: false),
        CardCompany(id: 'samsung', name: '삼성카드', format: 'Excel(.xls)', enabled: false),
        CardCompany(id: 'lotte', name: '롯데카드', format: 'CSV', enabled: false),
        CardCompany(id: 'hana', name: '하나카드', format: 'Excel(.xls)', enabled: false),
        CardCompany(id: 'nh', name: 'NH농협카드', format: 'Excel(.xlsx)', enabled: false),
        CardCompany(id: 'woori', name: '우리카드', format: 'Excel(.xls)', enabled: false),
        CardCompany(id: 'bc', name: 'BC카드', format: 'CSV', enabled: false),
      ];
}
