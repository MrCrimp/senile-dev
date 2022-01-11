Function Get-Something {
<#
.SYNOPSIS
    This is a basic overview of what the script is used for..
    (when using `Get-Help Get-Something -Examples`)
    
.NOTES
    Name: Get-Something
    Author: me
 
.EXAMPLE
    Get-Something -Foo "username"
 
 
.LINK
    https://helpurl
#>
 
    [CmdletBinding()]
    #[CmdletBinding(DefaultParameterSetName="Default")]
    # => Then use ParameterSetName on param groups, see example below
    param(

        # First param
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
            )]
        [Alias("SomethingElse", "OrEvenOther")]
        [ValidateSet('First-Valid-Value', 'other')]
        #[ValidateScript( {Get-ADUser -Filter "UserPrincipalName -eq '$_'" | select -ExpandProperty UserPrincipalName} )]
        [string[]]  $Foo,

        # Second param
        [Parameter(
            Mandatory = $false
        )]
        [ValidateRange(1,100)]
        [int[]] $someCount,

        # Third, Using parameter group
        [Parameter(
            Mandatory = $false,
            ParameterSetName = 'AnyName_A'    
        )]
        [switch]    $Include
    )
 
    # The code inside the begin and end block will only run once
    BEGIN {}
 
    # Main. Will iterate over all input objects. If you have objects coming in the pipeline or if you run a foreach loop
    PROCESS {}
 
    END {}
}