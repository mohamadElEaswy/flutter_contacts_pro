import 'package:flutter/foundation.dart';

/// Organization / employer details for a contact.
@immutable
class Organization {
  final String? company;
  final String? jobTitle;
  final String? department;
  final String? phoneticCompany;

  const Organization({
    this.company,
    this.jobTitle,
    this.department,
    this.phoneticCompany,
  });

  Organization copyWith({
    String? company,
    String? jobTitle,
    String? department,
    String? phoneticCompany,
  }) {
    return Organization(
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      department: department ?? this.department,
      phoneticCompany: phoneticCompany ?? this.phoneticCompany,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Organization &&
        other.company == company &&
        other.jobTitle == jobTitle &&
        other.department == department &&
        other.phoneticCompany == phoneticCompany;
  }

  @override
  int get hashCode =>
      Object.hash(company, jobTitle, department, phoneticCompany);

  @override
  String toString() =>
      'Organization(company: $company, jobTitle: $jobTitle, department: $department)';
}
