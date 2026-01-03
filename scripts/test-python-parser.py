#!/usr/bin/env python3
"""
Test du parser Python pour Yahoo Finance
Ce script simule le comportement du node Python dans n8n
"""

from datetime import datetime
import json

# Simuler une réponse Yahoo Finance typique
mock_yahoo_response = {
    "chart": {
        "result": [
            {
                "timestamp": [1704326400],  # 2024-01-04
                "indicators": {
                    "quote": [
                        {
                            "open": [745.20],
                            "high": [752.30],
                            "low": [742.10],
                            "close": [748.50],
                            "volume": [1234567]
                        }
                    ],
                    "adjclose": [
                        {
                            "adjclose": [748.50]
                        }
                    ]
                }
            }
        ]
    }
}

# Simuler les données stock_info
mock_stock_info = {
    "id": 1,
    "ticker": "MC.PA",
    "name": "LVMH"
}

def parse_yahoo_response(yahoo_response, stock_info):
    """
    Parser la réponse Yahoo Finance (équivalent au code n8n)
    """
    try:
        if yahoo_response.get('chart') and yahoo_response['chart'].get('result') and len(yahoo_response['chart']['result']) > 0:
            chart = yahoo_response['chart']['result'][0]
            quote = chart['indicators']['quote'][0]
            timestamp = chart['timestamp'][0]

            # Convertir timestamp en date
            date = datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d')

            # Récupérer adjusted close si disponible
            adj_close_data = chart['indicators'].get('adjclose')
            if adj_close_data and len(adj_close_data) > 0 and adj_close_data[0].get('adjclose'):
                adjusted_close = adj_close_data[0]['adjclose'][0]
            else:
                adjusted_close = quote['close'][0]

            return {
                'json': {
                    'stock_id': stock_info['id'],
                    'ticker': stock_info['ticker'],
                    'name': stock_info['name'],
                    'date': date,
                    'open': quote['open'][0],
                    'high': quote['high'][0],
                    'low': quote['low'][0],
                    'close': quote['close'][0],
                    'volume': quote['volume'][0],
                    'adjusted_close': adjusted_close,
                    'success': True
                }
            }
        else:
            return {
                'json': {
                    'stock_id': stock_info['id'] if stock_info else None,
                    'ticker': stock_info['ticker'] if stock_info else 'unknown',
                    'name': stock_info['name'] if stock_info else 'unknown',
                    'success': False,
                    'error': 'No data in response'
                }
            }
    except Exception as error:
        return {
            'json': {
                'stock_id': None,
                'ticker': 'error',
                'name': 'error',
                'success': False,
                'error': str(error)
            }
        }

# Tests
def test_successful_parse():
    """Test avec une réponse valide"""
    print("🧪 Test 1: Parsing d'une réponse valide")
    result = parse_yahoo_response(mock_yahoo_response, mock_stock_info)
    print(json.dumps(result, indent=2))
    assert result['json']['success'] == True
    assert result['json']['ticker'] == 'MC.PA'
    assert result['json']['close'] == 748.50
    print("✅ Test 1 réussi\n")

def test_empty_response():
    """Test avec une réponse vide"""
    print("🧪 Test 2: Parsing d'une réponse vide")
    empty_response = {"chart": {"result": []}}
    result = parse_yahoo_response(empty_response, mock_stock_info)
    print(json.dumps(result, indent=2))
    assert result['json']['success'] == False
    assert result['json']['error'] == 'No data in response'
    print("✅ Test 2 réussi\n")

def test_missing_adjclose():
    """Test sans adjusted close"""
    print("🧪 Test 3: Parsing sans adjusted close")
    response_no_adjclose = {
        "chart": {
            "result": [
                {
                    "timestamp": [1704326400],
                    "indicators": {
                        "quote": [
                            {
                                "open": [745.20],
                                "high": [752.30],
                                "low": [742.10],
                                "close": [748.50],
                                "volume": [1234567]
                            }
                        ]
                    }
                }
            ]
        }
    }
    result = parse_yahoo_response(response_no_adjclose, mock_stock_info)
    print(json.dumps(result, indent=2))
    assert result['json']['success'] == True
    assert result['json']['adjusted_close'] == result['json']['close']
    print("✅ Test 3 réussi\n")

def test_exception_handling():
    """Test de gestion d'erreur"""
    print("🧪 Test 4: Gestion des exceptions")
    invalid_response = {"invalid": "data"}
    result = parse_yahoo_response(invalid_response, mock_stock_info)
    print(json.dumps(result, indent=2))
    assert result['json']['success'] == False
    print("✅ Test 4 réussi\n")

if __name__ == "__main__":
    print("=" * 60)
    print("Tests du parser Python pour Yahoo Finance")
    print("=" * 60 + "\n")

    try:
        test_successful_parse()
        test_empty_response()
        test_missing_adjclose()
        test_exception_handling()

        print("=" * 60)
        print("✅ Tous les tests sont passés avec succès!")
        print("=" * 60)
    except AssertionError as e:
        print(f"❌ Échec du test: {e}")
    except Exception as e:
        print(f"❌ Erreur inattendue: {e}")
