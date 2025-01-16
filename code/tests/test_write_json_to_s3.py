import unittest
from unittest.mock import patch, Mock
import datetime
import boto3
from main import write_json_to_s3

# didn't write many tests because they're super simple functions and I'd just be mocking everything
class TestWriteJsonToS3(unittest.TestCase):
    def setUp(self):
        self.sample_dict = {"key1": "value1", "key2": "value2"}
        self.category = "test_category"
    
    @patch("main.connect_to_s3")
    def test_generate_key_without_overwrite(self, s3_mock: Mock):
        s3_mock.return_value = Mock()
        expected_key = f"movies_{self.category}_{datetime.datetime.today().strftime('%Y-%m-%d')}.json"
        key = write_json_to_s3(json_object=self.sample_dict, category=self.category, overwrite=False)
        self.assertEqual(key, expected_key)
    
    @patch("main.connect_to_s3")
    def test_generate_key_with_overwrite(self, s3_mock: Mock):
        s3_mock.return_value = Mock()
        expected_key = f"movies_{self.category}.json"
        key = write_json_to_s3(json_object=self.sample_dict, category=self.category, overwrite=True)
        self.assertEqual(key, expected_key)

if __name__ == "__main__":
    unittest.main()