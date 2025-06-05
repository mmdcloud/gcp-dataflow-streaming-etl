import json
from google.cloud import pubsub_v1
import random

# Configuration
project_id = "orbital-bee-455915-h5"
topic_id = "streaming-source"

# Sample data for generating records
first_names = ["John", "Jane", "Robert", "Emily", "Michael", "Sarah", "David", "Lisa", "James", "Emma"]
last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Miller", "Davis", "Garcia", "Rodriguez", "Wilson"]
cities = ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose"]
categories = ["Indoor", "Outdoor"]  # Only two possible categories

# Initialize Pub/Sub publisher
publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(project_id, topic_id)

def generate_records(count=10):
    """Generate sample records in JSON format with category field"""
    records = []
    for i in range(count):
        record = {
            "name": f"{random.choice(first_names)} {random.choice(last_names)}",
            "email": f"{random.choice(first_names).lower()}.{random.choice(last_names).lower()}@example.com",
            "city": random.choice(cities),
            "category": random.choice(categories)  # Randomly select Indoor or Outdoor
        }
        records.append(record)
    return records

def publish_records(records):
    """Publish records to Pub/Sub topic"""
    for record in records:
        # Convert record to JSON string
        data = json.dumps(record).encode("utf-8")
        # Publish to Pub/Sub
        future = publisher.publish(topic_path, data)
        print(f"Published record: {record} (message ID: {future.result()})")

if __name__ == "__main__":
    # Generate 10 sample records
    records = generate_records(10)
    
    # Print the records (for verification)
    print("Generated records:")
    for i, record in enumerate(records, 1):
        print(f"{i}. {json.dumps(record)}")
    
    # Count categories for verification
    indoor_count = sum(1 for record in records if record['category'] == "Indoor")
    outdoor_count = sum(1 for record in records if record['category'] == "Outdoor")
    print(f"\nCategory distribution: Indoor={indoor_count}, Outdoor={outdoor_count}")
    
    # Publish the records
    print("\nPublishing records to Pub/Sub...")
    publish_records(records)
    print("Done!")