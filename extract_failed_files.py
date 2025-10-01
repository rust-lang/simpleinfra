#!/usr/bin/env python3
"""
Extract all failed files from Google Cloud Storage Transfer Service operations
"""
import json
import subprocess
import sys
from collections import defaultdict

def run_gcloud_command(cmd):
    """Run gcloud command and return JSON output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"Error running command: {cmd}", file=sys.stderr)
            print(f"Error: {result.stderr}", file=sys.stderr)
            return None
        return json.loads(result.stdout) if result.stdout.strip() else None
    except json.JSONDecodeError as e:
        print(f"Failed to parse JSON from command: {cmd}", file=sys.stderr)
        print(f"Output: {result.stdout}", file=sys.stderr)
        return None

def extract_failed_files_from_operation(operation_name, project_id):
    """Extract failed files from a single transfer operation"""
    cmd = f'gcloud transfer operations describe {operation_name} --project={project_id} --format=json'
    operation_data = run_gcloud_command(cmd)
    
    if not operation_data or 'metadata' not in operation_data:
        return []
    
    failed_files = []
    metadata = operation_data['metadata']
    
    # Extract job name for context
    job_name = metadata.get('transferJobName', 'unknown')
    bucket_name = 'unknown'
    
    if 'transferSpec' in metadata:
        if 'awsS3DataSource' in metadata['transferSpec']:
            bucket_name = metadata['transferSpec']['awsS3DataSource'].get('bucketName', 'unknown')
    
    # Extract error breakdowns
    if 'errorBreakdowns' in metadata:
        for error_breakdown in metadata['errorBreakdowns']:
            error_code = error_breakdown.get('errorCode', 'UNKNOWN')
            error_count = int(error_breakdown.get('errorCount', 0))
            
            # Note: errorLogEntries only shows a sample, not all failed files
            if 'errorLogEntries' in error_breakdown:
                for error_entry in error_breakdown['errorLogEntries']:
                    failed_files.append({
                        'operation': operation_name,
                        'job_name': job_name,
                        'bucket': bucket_name,
                        'url': error_entry.get('url', ''),
                        'error_code': error_code,
                        'error_details': error_entry.get('errorDetails', []),
                        'total_errors_this_type': error_count
                    })
    
    return failed_files

def main():
    project_id = 'rust-asset-backup-production'
    
    # List of failed operations we know about
    failed_operations = [
        'transferOperations/transferJobs-transfer-crates-io-8112795250505597565',
        'transferOperations/transferJobs-transfer-static-rust-lang-org-205732933237355629',
        'transferOperations/transferJobs-transfer-crates-io-14989467690258957078',
        'transferOperations/transferJobs-transfer-static-rust-lang-org-6742344679027984831'
    ]
    
    all_failed_files = []
    error_summary = defaultdict(int)
    bucket_summary = defaultdict(lambda: defaultdict(int))
    
    print("Extracting failed files from transfer operations...")
    print("=" * 60)
    
    for operation in failed_operations:
        print(f"Processing {operation}")
        failed_files = extract_failed_files_from_operation(operation, project_id)
        all_failed_files.extend(failed_files)
        
        # Update summaries
        for file_info in failed_files:
            error_summary[file_info['error_code']] += 1
            bucket_summary[file_info['bucket']][file_info['error_code']] += 1
    
    # Print summary
    print(f"\nSUMMARY:")
    print(f"Total sample failed files extracted: {len(all_failed_files)}")
    print(f"\nError types:")
    for error_code, count in error_summary.items():
        print(f"  {error_code}: {count} sample files")
    
    print(f"\nBy bucket:")
    for bucket, errors in bucket_summary.items():
        print(f"  {bucket}:")
        for error_code, count in errors.items():
            print(f"    {error_code}: {count} sample files")
    
    # Group by error type and bucket
    print(f"\n" + "=" * 80)
    print("DETAILED FAILED FILES LIST")
    print("=" * 80)
    
    # Group files by bucket and error code
    grouped_files = defaultdict(lambda: defaultdict(list))
    for file_info in all_failed_files:
        grouped_files[file_info['bucket']][file_info['error_code']].append(file_info)
    
    for bucket, error_groups in grouped_files.items():
        print(f"\n🪣 BUCKET: {bucket}")
        print("-" * 50)
        
        for error_code, files in error_groups.items():
            print(f"\n  ❌ ERROR TYPE: {error_code}")
            
            # Show total count for this error type
            total_count = files[0]['total_errors_this_type'] if files else 0
            print(f"     Total files with this error: {total_count}")
            print(f"     Sample files shown: {len(files)}")
            print()
            
            for i, file_info in enumerate(files, 1):
                file_url = file_info['url'].replace(f"s3://{bucket}/", "")
                print(f"     {i:2d}. {file_url}")
                if file_info['error_details']:
                    error_detail = file_info['error_details'][0]
                    # Truncate very long error messages
                    if len(error_detail) > 100:
                        error_detail = error_detail[:100] + "..."
                    print(f"         Error: {error_detail}")
    
    # Write detailed JSON output
    output_file = '/Users/marco/proj/simpleinfra/failed_files_detailed.json'
    with open(output_file, 'w') as f:
        json.dump({
            'summary': {
                'total_sample_files': len(all_failed_files),
                'error_summary': dict(error_summary),
                'bucket_summary': {k: dict(v) for k, v in bucket_summary.items()}
            },
            'failed_files': all_failed_files
        }, f, indent=2)
    
    print(f"\n📄 Detailed JSON output written to: {output_file}")
    
    # Important note about limitations
    print(f"\n" + "⚠️ " * 20)
    print("IMPORTANT NOTE:")
    print("The Google Cloud Transfer Service API only returns a SAMPLE of failed files")
    print("in the errorLogEntries (typically 5 per error type). The actual number of")
    print("failed files is shown in the 'total_errors_this_type' field.")
    print("")
    print("From the operations analyzed:")
    for operation in failed_operations:
        cmd = f'gcloud transfer operations describe {operation} --project={project_id} --format="value(metadata.counters.objectsFromSourceFailed)"'
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode == 0 and result.stdout.strip():
            failed_count = result.stdout.strip()
            operation_short = operation.split('/')[-1]
            print(f"  {operation_short}: {failed_count} total failed files")

if __name__ == '__main__':
    main()