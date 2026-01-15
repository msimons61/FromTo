//
//  CurrencyRateService.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import Foundation

/// Service for fetching currency exchange rates from Frankfurter API
class CurrencyRateService {
    static let shared = CurrencyRateService()

    private init() {}

    /// Fetches the exchange rate from base currency to target currency for a specific date
    /// - Parameters:
    ///   - baseCurrency: The base currency code (e.g., "USD")
    ///   - targetCurrency: The target currency code (e.g., "EUR")
    ///   - date: The date for which to fetch the rate
    /// - Returns: The exchange rate as a Decimal, or nil if the fetch fails
    func fetchRate(from baseCurrency: String, to targetCurrency: String, on date: Date) async throws -> Decimal {
        // If currencies are the same, return 1.0
        guard baseCurrency != targetCurrency else {
            return 1.0
        }

        // Format date as YYYY-MM-DD
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let dateString = formatter.string(from: date)

        // Build URL
        let urlString = "https://api.frankfurter.dev/v1/\(dateString)?base=\(baseCurrency)&symbols=\(targetCurrency)"
        guard let url = URL(string: urlString) else {
            throw CurrencyRateError.invalidURL
        }

        // Fetch data
        let (data, response) = try await URLSession.shared.data(from: url)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CurrencyRateError.invalidResponse
        }

        // Parse JSON
        let decoder = JSONDecoder()
        let result = try decoder.decode(FrankfurterResponse.self, from: data)

        // Extract rate
        guard let rate = result.rates[targetCurrency] else {
            throw CurrencyRateError.rateNotFound
        }

        return Decimal(rate)
    }
}

// MARK: - Response Model
private struct FrankfurterResponse: Codable {
    let amount: Double
    let base: String
    let date: String
    let rates: [String: Double]
}

// MARK: - Error Types
enum CurrencyRateError: LocalizedError {
    case invalidURL
    case invalidResponse
    case rateNotFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Could not fetch exchange rate"
        case .rateNotFound:
            return "Exchange rate not found for currency pair"
        }
    }
}
