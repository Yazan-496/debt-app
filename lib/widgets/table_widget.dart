import 'package:flutter/material.dart';

class TableWidget extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double? scale;
  final Offset? offset;
  final Function(double)? onScaleChanged;
  final Function(Offset)? onOffsetChanged;
  final Function()? onResetZoom;
  final Function()? onZoomIn;
  final Function()? onZoomOut;
  final Color? headingRowColor;
  final Color? dataRowColor;
  final double? fontSize;
  final double? iconSize;
  final double? padding;
  final bool isLoading;

  const TableWidget({
    super.key,
    required this.columns,
    required this.rows,
    this.scale,
    this.offset,
    this.onScaleChanged,
    this.onOffsetChanged,
    this.onResetZoom,
    this.onZoomIn,
    this.onZoomOut,
    this.headingRowColor,
    this.dataRowColor,
    this.fontSize,
    this.iconSize,
    this.padding,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isSmallScreen = screenWidth < 600;
        final isVerySmallScreen = screenWidth < 400;
        final defaultFontSize =
            isVerySmallScreen ? 10.0 : (isSmallScreen ? 11.0 : 12.0);
        final defaultPadding =
            isVerySmallScreen ? 4.0 : (isSmallScreen ? 8.0 : 12.0);

        Widget tableContent = Container(
          margin: EdgeInsets.symmetric(vertical: padding ?? defaultPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              isLoading
                  ? SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.green),
                          const SizedBox(height: 16),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: fontSize ?? defaultFontSize,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          headingRowColor ?? Colors.green[50],
                        ),
                        columnSpacing: 0,
                        horizontalMargin: 0,
                        dividerThickness: 0,
                        headingRowHeight: 40,
                        dataRowHeight: 40,
                        headingTextStyle: TextStyle(
                          fontSize: fontSize ?? defaultFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        columns: columns,
                        rows: rows,
                      ),
                    ],
                  ),
        );

        if (scale != null && offset != null) {
          tableContent = Transform(
            transform:
                Matrix4.identity()
                  ..translate(offset!.dx, offset!.dy)
                  ..scale(scale!),
            child: tableContent,
          );
        }

        return Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child:
                  scale != null && offset != null
                      ? GestureDetector(
                        onScaleStart: (details) {
                          onOffsetChanged?.call(details.localFocalPoint);
                        },
                        onScaleUpdate: (details) {
                          final newScale = (scale! * details.scale).clamp(
                            1.0,
                            2.0,
                          );
                          onScaleChanged?.call(newScale);

                          final newOffset =
                              offset! + (details.localFocalPoint - offset!);
                          final maxOffsetX = (screenWidth * (newScale - 1)) / 2;
                          final maxOffsetY =
                              (screenHeight * (newScale - 1)) / 2;

                          onOffsetChanged?.call(
                            Offset(
                              newOffset.dx.clamp(-maxOffsetX, maxOffsetX),
                              newOffset.dy.clamp(-maxOffsetY, maxOffsetY),
                            ),
                          );
                        },
                        onScaleEnd: (details) {
                          onScaleChanged?.call(scale!.clamp(1.0, 2.0));
                          onOffsetChanged?.call(
                            Offset(
                              offset!.dx.clamp(
                                -(screenWidth * (scale! - 1)) / 2,
                                (screenWidth * (scale! - 1)) / 2,
                              ),
                              offset!.dy.clamp(
                                -(screenHeight * (scale! - 1)) / 2,
                                (screenHeight * (scale! - 1)) / 2,
                              ),
                            ),
                          );
                        },
                        child: tableContent,
                      )
                      : tableContent,
            ),
            if (scale != null && offset != null)
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (scale != 1.0 || offset != Offset.zero)
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.green,
                        onPressed: onResetZoom,
                        child: const Icon(
                          Icons.zoom_out_map,
                          color: Colors.white,
                        ),
                      ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.green,
                      onPressed: onZoomIn,
                      child: const Icon(Icons.zoom_in, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.green,
                      onPressed: onZoomOut,
                      child: const Icon(Icons.zoom_out, color: Colors.white),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
