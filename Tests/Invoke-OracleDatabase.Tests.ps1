Describe 'Invoke-OracleDatabase' {
    It 'Should have sqlplus installed' {
        {sqlplus -v} |Should Not throw
    }
}